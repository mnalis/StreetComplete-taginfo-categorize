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

my $min_percent = 0.01;	# add keys which occur more often than this percentage (NOTE: can't go below 0.01%)

# load existing keys
my @existing = ();

open my $existing_fd, '<', 'keys.txt';
while (<$existing_fd>) {
    next unless /^[a-z.]/i;	# line could start with regex like ".*xxxx"
    chomp;
    s{\s*(#|//).*$}{};		# remove inline comments
    s/([^\.])\*/$1.*/;		# make "*" wildcard into regex internally (if not regex already). NOTE: not perfect, but works for us!
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
if (defined $json_file and $json_file =~ /^([a-z_=-]*.json)$/) { $json_file = $1 } else { die "invalid JSON filename" }
my $max_tags = $ARGV[1];
if (defined $max_tags and $max_tags =~ /^(\d+)$/) { $max_tags = $1 } else { die "invalid max_tags" }

open my $json_fd, '<', $json_file;
local $/;
my $json_all = (decode_json <$json_fd>)[0]->{'data'};
my @json_fraction = grep { $_->{'to_fraction'} * 100 > $min_percent } @$json_all;
my @json_filtered = grep { is_new($_->{'other_key'}) } @json_fraction;
my @tags_many = map { $_->{'other_key'} } @json_filtered;

my $all_count  = scalar @$json_all;
my $fraction_count  = scalar @json_fraction;
my $done_count = scalar @tags_many;
#say STDERR "TEST $json_file: todo $done_count/$fraction_count/$all_count/$max_tags tags";

if (@tags_many) {
    say "\n// from $json_file";
    say join "\n", @tags_many;
}

if (($fraction_count == $all_count) and ($all_count == $max_tags)) {
    say STDERR "WARNING $json_file: added $done_count/$all_count tags; but you need to fetch bigger .JSON in Makefile!";
} else {
    say STDERR "UPDATE $json_file: added $done_count/$all_count unclassified tags" if @tags_many;
}
