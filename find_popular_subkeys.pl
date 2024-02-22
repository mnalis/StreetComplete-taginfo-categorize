#!/usr/bin/perl
# by Matija Nalis <mnalis-git@voyager.hr> GPLv3+, started 20210921
#
# parse taginfo.openstreetmap.org popular values for "shop=*" and "craft=*"
# and find values which themselves are popular subkeys

use warnings;
use strict;
use autodie qw/:all/;
use feature 'say';
use Carp 'verbose';

$SIG{__DIE__} = \&Carp::confess; # umjesto croak, da dobijemo stack trace

use JSON;

my $MIN_VALUE_COUNT = 100;	# ignore values  with less than this many occurances (eg. keep shop=scooter as it has 113 occurances, and 113 > 100)
my $MIN_SUBKEY_COUNT = 90;	# ignore subkeys with less than this many occurances (eg. keep scooter=* as it has 2093 occurances, and 2093 > 90)

# slurps multiline JSON output from a command, and returns it as a string
sub slurp_cmd($) {
    my ($cmd) = @_;

    open my $json_fd, '-|', $cmd;
    my $output;
    { local $/; $output = <$json_fd>; }
    #say "DEBUG: JSON text output=$output";
    return $output;
}

# parse one JSON file and return its main "data" array.
sub get_json($) {
    my ($cmd) = @_;
    my @json = decode_json (slurp_cmd($cmd));
    return $json[0]->{'data'};;
    # FIXME error:
    #       00000000  73 6f 63 69 c3 a9 74 c3  a9 5f                    |soci..t.._|    //  "value": "société_de_boule_de_fort",
    
    # ./find_popular_subkeys.pl club.json2 craft.json2 healthcare.json2 office.json2 shop.json2 > _find_popular_subkeys.txt.tmp && mv -f _find_popular_subkeys.txt.tmp _find_popular_subkeys.txt
    # Fetching (club.json2): sport yes scout social freemasonry music culture automobile veterans sailing soci�t�_de_boule_de_fort malformed JSON string, neither tag, array, object, number, string or atom, at character offset 0 (before "invalid URL") at ./find_popular_subkeys.pl line 22, <$_[...]> chunk 1.
    # make: *** [Makefile:80: _find_popular_subkeys.txt] Error 255
    
    #Fetching (club.json2): sport sport      # subkey count=2621246
    #yes #yes        # ignore, subkey count=0 < 90
    #scout scout     # subkey count=1170
    #social #social  # ignore, subkey count=80 < 90
    #freemasonry #freemasonry        # ignore, subkey count=1 < 90
    #music music     # subkey count=352
    #culture culture # subkey count=436
    #automobile #automobile  # ignore, subkey count=11 < 90
    #veterans #veterans      # ignore, subkey count=0 < 90
    #sailing #sailing        # ignore, subkey count=7 < 90
    #soci�t�_de_boule_de_fort malformed JSON string, neither tag, array, object, number, string or atom, at character offset 0 (before "invalid URL") at ./find_popular_subkeys.pl line 34.
    # at ./find_popular_subkeys.pl line 34.
    #        main::get_json("curl --silent 'https://taginfo.openstreetmap.org/api/4/key/st"...) called at ./find_popular_subkeys.pl line 74


}



while (my $json_file = shift @ARGV) {
    my $json_all = get_json "cat $json_file";
    my @json_fraction = grep { $_->{'count'} >= $MIN_VALUE_COUNT } @$json_all;
    my @values_many =  map { $_->{'value'} } @json_fraction;

    print STDERR "Fetching ($json_file): ";
    foreach my $key (@values_many) {
        print STDERR "$key ";
        my $url = "https://taginfo.openstreetmap.org/api/4/key/stats?key=$key";
        my $subjson_all = get_json "curl --silent '$url'";
        my $subkeys_count = (map { $_->{'count'} } grep { $_->{'type'} eq 'all' } @$subjson_all)[0];

        #say STDERR "subkeys_count=$subkeys_count";
        if ($subkeys_count > $MIN_SUBKEY_COUNT) {
            say "$key\t# subkey count=$subkeys_count"
        } else {
            say "#$key\t# ignore, subkey count=$subkeys_count < $MIN_SUBKEY_COUNT"
        }
    }

    print STDERR "\n";
    print "\n";
}
