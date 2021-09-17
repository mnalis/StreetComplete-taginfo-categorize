#!/usr/bin/perl -T
# by Matija Nalis <mnalis-git@voyager.hr> GPLv3+, started 20210917
#
# parse id-tagging-schema/data/presets/*

use strict;
use warnings;
use autodie qw/:all/;
use feature 'say';

use JSON;

use Data::Dumper;

my $BASEDIR=undef;

# parse one possible value (one key name)
sub parse_value($)
{
    my ($value) = @_;

    if ($value =~ /^{(.*)}/) {
        my $new_file = "${BASEDIR}$1.json";
        parse_preset ($new_file);	# recursive parse
    } else {
        $value =~ tr{/}{:};
        $value =~ s{_multi$}{:.*};	# NOTE: ideally we should be parsing data/fields/*.json
        return if $value =~ /building_area|height_building/;
        say $value;
    }
}

# parse all fields/moreFields in one given preset JSON file
sub parse_preset($)
{
    my ($json_file) = @_;

    say "# parsing file: $json_file";
    open my $json_fd, '<', $json_file;
    local $/;
    my $json_all = decode_json <$json_fd>;

    my $fields_ref = $json_all->{'fields'};
    foreach my $k (@$fields_ref) { parse_value($k) };

    my $morefields_ref = $json_all->{'moreFields'};
    foreach my $k (@$morefields_ref) { parse_value($k) };
}

#######
# MAIN
#######
while (my $arg = shift @ARGV) {
    if (!defined $BASEDIR) { $BASEDIR = $arg; $BASEDIR =~ s{^(.*/data/presets/).*$}{$1}; }
    parse_preset($arg)
}


#say STDERR "end.";

exit 0;
