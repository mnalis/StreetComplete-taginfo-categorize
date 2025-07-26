#!/usr/bin/perl -T
# by Matija Nalis <mnalis-git@voyager.hr> GPLv3+, started 20210905
#
# parses keys.txt and generates sc_to_remove.txt kotlin code in nicely commented blocks
# see README.md for description of structure

use strict;
use warnings;
use autodie qw/:all/;
use feature 'say';

my $MAX_LINE_LEN = 100;		# wrap the line if more than this chars

my $SECTION_START = shift @ARGV;
my $SECTION_END = shift @ARGV;
my $VAR_NAME = shift @ARGV;
my $SKIP_KEYS = shift @ARGV;

die "Usage: $0 <SECTION_START> <SECTION_END> <VAR_NAME>" if !defined $VAR_NAME;

my $kotlin_str = "private val $VAR_NAME = listOf(\n    ";	# start with default indent

open my $existing_fd, '<', 'keys.txt';

my $skip_it = 1;
while (<$existing_fd>) {
    if (/^$SECTION_START/) { $skip_it=0; next; }
    if (/^$SECTION_END/) { last; }
    if ($skip_it) { next; }
    chomp;

    if (m{^[a-z.(]}i) {		# detect key; line could start with regex like ".*xxxx" or "(abandoned|disused):"
        s{\s*(#|//).*$}{};		# remove inline comments
        next if $SKIP_KEYS && /${SKIP_KEYS}/;             # used to skip e.g. check_date:$key and source:$key which are automagically ignored by StreetComplete, see https://github.com/streetcomplete/StreetComplete/issues/6057
        s/([^\.])\*/$1.*/;		# make "*" wildcard into regex internally (if not regex already). NOTE: not perfect, but works for us!
        my $newstr = qq{"$_", };
        my $last_line_len = length($kotlin_str) - rindex ($kotlin_str, "\n") - 1;
        #say STDERR "len($newstr)=" . length $newstr;
        #say STDERR "  lastlinelen(" . substr($kotlin_str, 1+rindex($kotlin_str,"\n")) . ")=$last_line_len";
        if ($last_line_len + length $newstr > $MAX_LINE_LEN) {
            if ($kotlin_str =~ / $/) { $kotlin_str = substr($kotlin_str, 0, -1); }
            $kotlin_str .= "\n    ";
        }
        $kotlin_str .= $newstr;
    } elsif (m{^//}) {		# detect whole-line-//-comment
        $kotlin_str .= "$_\n    ";
    } elsif (m{^#}) {		# detect whole-line-#-comment
        next;
    } elsif (m{^\s*$}) {	# detect empty line
        if ($kotlin_str =~ / $/) { $kotlin_str = substr($kotlin_str, 0, -1); }
        $kotlin_str .= "\n    ";
    } else {
        warn "SKIPPING unparseable line: $_";
    }

    #say STDERR "DEBUG: line: $_";
}

if ($kotlin_str =~ /    $/) { $kotlin_str = substr($kotlin_str, 0, -4); }
print $kotlin_str;

say ')
    .flatMap { listOf(it, "source:$it", "check_date:$it") }
    .map { it.toRegex() }';
exit 0;
