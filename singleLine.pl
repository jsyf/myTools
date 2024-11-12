#!/usr/bin/perl
use strict;

chomp(my @cmd = <>);
print join(' ; ', (grep {$_ ne ''} @cmd))."\n";;
