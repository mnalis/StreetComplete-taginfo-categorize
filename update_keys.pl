#!/usr/bin/perl -T
# by Matija Nalis <mnalis-git@voyager.hr> GPLv3+, started 20210905
#
# parse taginfo.openstreetmap.org output for a list of OSM keys like:
# https://taginfo.openstreetmap.org/api/4/key/combinations?key=shop&filter=all&sortname=to_count&sortorder=desc&page=1&rp=501&qtype=other_key&format=json_pretty
# and add any keys with usage > 0.01% and not already present in keys.txt into it.

use strict;
use warnings;
use autodie qw/:all/;
use feature 'say';

use JSON;

my $min_fraction = 0.01;	# ignore keys which occur less often than this fraction (1=100%)

# load existing keys
my @existing = ();

open my $existing_fd, '<', 'keys.txt';
while (<$existing_fd>) {
    next unless /^[[:alpha:]]/i;
    chomp;
    s/([^\.])\*/$1.*/;		# make "*" wildcard into regex internally (if not regex already)
    push @existing, $_;
}

# returns false if the specified key is already present in keys.txt
sub is_new($)
{
    my ($key) = @_;
    #say "checking if $key is existing...";
    foreach my $old (@existing) {
        return 0 if $key =~ /^${old}$/;	# slow but simple and handle regexes
    }
    return 1;
}

# parse new keys

open my $json_fd, '<', 'shop.json';
local $/;
my $json_all = (decode_json <$json_fd>)[0]->{'data'};
my @json_filtered = grep { ($_->{'to_fraction'} > $min_fraction) and is_new($_->{'other_key'}) } @$json_all;
my @tags_many = map { lc $_->{'other_key'} } @json_filtered;

say join "\n", @tags_many;
