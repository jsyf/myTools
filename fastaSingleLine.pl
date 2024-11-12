#!/usr/bin/env perl
use strict;

if (@ARGV != 2) {
  print 'Usage: perl '.$0.' input.fasta output.fasta'."\n";
  exit;
}

my ($in, $out) = @ARGV;

if (!-e $in) {
  print 'Input fasta file ("'.$in.'") not found!'."\n";
  exit;
}

if (-e $out) {
  print 'Output fasta exists!'."\n";
  print 'Overwrite? (y/n)';
  chomp(my $ans = <STDIN>);

  if ((lc($ans) ne 'y') && (lc($ans) ne 'yes')) {
    exit;
  }
}

open(OUT,'>'.$out);
open(IN,'<'.$in);
while (<IN>) {
  chomp;
  if ($_ eq '') {
    next;
  }

  $_ =~ s/[\r\s\n]*$//;

  if ($_ =~ /^>/) {
    if ($. != 1) {
      print OUT "\n";
    }
    print OUT $_."\n";
  }
  else {
    print OUT $_;
  }
}
close(IN);
print OUT "\n";
close(OUT);
