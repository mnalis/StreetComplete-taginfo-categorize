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

my $min_fraction = 0.0001;	# ignore keys which occur less often than this fraction (0.0001 = 0.01%)

# load existing keys
my @existing = ();

open my $existing_fd, '<', 'keys.txt';
while (<$existing_fd>) {
    next unless /^[[:alpha:]]/i;
    chomp;
    s{\s*(#|//).*$}{};		# remove inline comments
    s/([^\.])\*/$1.*/;		# make "*" wildcard into regex internally (if not regex already)
    push @existing, $_;
    #say STDERR "existing key: $_";
}

# returns false if the specified key is already present in keys.txt
sub is_new($)
{
    my ($key) = @_;
    #say STDERR "checking if $key is existing...";
    foreach my $old (@existing) {
        return 0 if $key =~ /^${old}$/;	# slow but simple and handle regexes
    }
    return 1;
}

# parse new keys
my $json_file = $ARGV[0];
if (defined $json_file and $json_file =~ /^([a-z]*.json)$/) { $json_file = $1 } else { die "invalid filename" }
open my $json_fd, '<', $json_file;
local $/;
my $json_all = (decode_json <$json_fd>)[0]->{'data'};
my @json_filtered = grep { ($_->{'to_fraction'} > $min_fraction) and is_new($_->{'other_key'}) } @$json_all;
my @tags_many = map { $_->{'other_key'} } @json_filtered;

if (@tags_many) {
    say "// $json_file";
    say join "\n", @tags_many;
}
