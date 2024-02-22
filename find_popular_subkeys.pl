#!/usr/bin/perl
# by Matija Nalis <mnalis-git@voyager.hr> GPLv3+, started 20210921
#
# parse taginfo.openstreetmap.org popular values for "shop=*" and "craft=*"
# and find values which themselves are popular subkeys

use warnings;
use strict;
use autodie qw/:all/;
use feature 'say';

use JSON;
use URI::Escape;

my $MIN_VALUE_COUNT = 100;	# ignore values  with less than this many occurances (eg. keep shop=scooter as it has 113 occurances, and 113 > 100)
my $MIN_SUBKEY_COUNT = 90;	# ignore subkeys with less than this many occurances (eg. keep scooter=* as it has 2093 occurances, and 2093 > 90)

# slurps multiline JSON output from a command, and returns it as a string
sub slurp_cmd($) {
    my ($cmd) = @_;

    open my $json_fd, '-|', $cmd;
    my $output;
    #say "DEBUG: running JSON cmd: $cmd";
    { local $/; $output = <$json_fd>; }
    #say "DEBUG: JSON text output: $output";
    return $output;
}

# parse one JSON file and return its main "data" array.
sub get_json($) {
    my ($cmd) = @_;
    my @json = decode_json (slurp_cmd($cmd));
    return $json[0]->{'data'};;
}



while (my $json_file = shift @ARGV) {
    my $json_all = get_json "cat $json_file";
    my @json_fraction = grep { $_->{'count'} >= $MIN_VALUE_COUNT } @$json_all;
    my @values_many =  map { $_->{'value'} } @json_fraction;

    print STDERR "Fetching ($json_file): ";
    foreach my $key (@values_many) {
        print STDERR "$key ";
        my $url = 'https://taginfo.openstreetmap.org/api/4/key/stats?key=' . uri_escape($key);
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
