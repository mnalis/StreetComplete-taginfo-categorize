#!/usr/bin/perl -T
# by Matija Nalis <mnalis-git@voyager.hr> GPLv3+, started 20210917
#
# parse id-tagging-schema/data/presets

use strict;
use warnings;
use autodie qw/:all/;
use feature 'say';

use JSON;

say $ARGV[0];