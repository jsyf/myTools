#!/usr/bin/env perl
use strict;

my $fn = shift;
my $fOut = shift;

my %nonEmpty;

open(IN, '<'.$fn);
while (<IN>) {
  chomp;
  if ($_ eq '') {
    next;
  }

  my @array = split("\t", $_);

  if ($. == 1) {
    next;
  }

  for (my $i=0;$i<@array;$i ++) {
    if ($nonEmpty{$i}) {
      next;
    }

    if ($array[$i] ne '') {
      $nonEmpty{$i} = 1;
    }
  }
}
close(IN);

my @pickCol = sort{$a <=> $b} (keys %nonEmpty);

open(OUT, '>'.$fOut);
open(IN, '<'.$fn);
while (<IN>) {
  chomp;
  if ($_ eq '') {
    next;
  }

  my @array = split("\t", $_);

  print OUT join("\t", @array[@pickCol])."\n";
}
close(IN);
close(OUT);
