#!/usr/bin/perl -T
# by Matija Nalis <mnalis-git@voyager.hr> GPLv3+, started 20210905
#
# parses keys.txt and generates sc_to_remove.txt kotlin code in nicely commented blocks
# see README.md for description of structure

use strict;
use warnings;
use autodie qw/:all/;
use feature 'say';

my $SECTION_START = qr/^### KEYS TO REMOVE ###/;
my $SECTION_END = qr/^### KEYS TO/;

say 'val KEYS_THAT_SHOULD_BE_REMOVED_WHEN_SHOP_IS_REPLACED = listOf(';
print '    ';	# default indent

# FIXME	sed -ne '1,/PROBABLY REMOVE/s/^\([a-z.]\)/\1/p' keys.txt | sed -e 's,[ \t]*//.*$$,,; s,\([^.]\)\*,\1.*,g; s/^/"/; s/$$/",/' | fmt >> $@

open my $existing_fd, '<', 'keys.txt';


my $skip_it = 1;
while (<$existing_fd>) {
    if (/$SECTION_START/) { $skip_it=0; next; }
    if (/$SECTION_END/) { last; }
    if ($skip_it) { next; }
    chomp;

    if (m{^[a-z.]}i) {		# detect key; line could start with regex like ".*xxxx"
        s{\s*(#|//).*$}{};		# remove inline comments
        s/([^\.])\*/$1.*/;		# make "*" wildcard into regex internally (if not regex already). NOTE: not perfect, but works for us!
        print qq{"$_", };
    } elsif (m{^//}) {		# detect whole-line-//-comment
        print "\n    $_\n    ";
    } elsif (m{^#}) {		# detect whole-line-#-comment
        next;
    } elsif (m{^\s*$}) {	# detect empty line
        print "\n    ";
    } else {
        warn "SKIPPING unparseable line: $_";
    }

    #say STDERR "DEBUG: line: $_";
}

say ').map { it.toRegex() }';
exit 0;
