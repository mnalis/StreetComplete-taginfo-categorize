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
my %KEYS=();

# parse one possible value (one key name)
sub parse_value($)
{
    my ($value) = @_;

    if ($value =~ /^{(.*)}/) {
        my $new_file = "${BASEDIR}$1.json";
        parse_preset ($new_file);	# recursive parse
    } else {
        $value =~ tr{/}{:};
        #say STDERR "V: $value";
        $KEYS{$value}=1;
    }
}

# parse all fields/moreFields in one given preset JSON file
sub parse_preset($)
{
    my ($json_file) = @_;

    #say STDERR "parsing file: $json_file";
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

foreach my $key (keys %KEYS) {
    say $key;
}

#say STDERR "end.";

exit 0;
