#!/usr/bin/env perl
use strict;

if (@ARGV != 3) {
  print "Usage: perl $0 Mapping.txt inputBiom outputBiom\n";
  exit;
}

my @sampleOrder;
my $sampleNameIdx = 0;
open(IN,'<'.$ARGV[0]);
while (<IN>) {
  chomp;
  if ($_ eq '') {
    next;
  }

  if ($. == 1) {
    $_ =~ s/^#+//;

    my @array = split("\t",$_);

    for (my $i=0;$i<@array;$i++) {
      if ($array[$i] eq 'SampleID') {
        $sampleNameIdx = $i;
      }
    }
    next;
  }

  my @array = split("\t",$_);

  push(@sampleOrder,$array[$sampleNameIdx]);
}
close(IN);

my $check = 0;
open(OUT,'>'.$ARGV[2]);
open(IN,'<'.$ARGV[1]);
while (<IN>) {
  chomp;
  if ($_ eq '') {
    next;
  }

  my $line = $_;

  if ($check == 0) {
    print OUT $line."\n";
  }

  if ($line =~ /\s+"columns":\[/) {
    $check = 1;
  }

  if ($check == 0) {
    next;
  }

  my %cols;
  while (<IN>) {
    chomp;
    if ($_ eq '') {
      next;
    }

    my $line2 = $_;

    if ($line2 =~ /^\s+],/) {
      foreach my $sampleName (@sampleOrder) {
        print OUT $cols{$sampleName};
        if ($sampleName ne $sampleOrder[$#sampleOrder]) {
          print OUT ',';
        }
        print OUT "\n";
      }

      print OUT $line2."\n";
      $check = 0;
      last;
    }
    elsif ($line2 =~ /"id":"([^\"]+)"/) {
      my $sampleName = $1;

      $line2 =~ s/,\s*$//;

      $cols{$sampleName} = $line2;
    }
  }
}
close(IN);
close(OUT);
