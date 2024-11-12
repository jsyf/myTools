#!/usr/bin/env perl
use strict;

use utf8;
binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');

sub csvsplit { 
  my $line = shift; 
  my $sep = (shift or ','); 
  return () unless $line; 
  my @cells; 
  $line =~ s/\r?\n$//; 
  my $re = qr/(?:^|$sep)(?:"([^"]*)"|([^$sep]*))/; 
  while($line =~ /$re/g) { 
    my $value = defined $1 ? $1 : $2; 
    push @cells, (defined $value ? $value : ''); 
  } 
  return @cells; 
}

my $fn = shift;
my $sep = (shift or "\t");

if (($fn ne '-') && (!-e $fn)) {
  print 'File not found!'.$/;
  exit;
}

my @colWid;
open(IN,'<:encoding(utf8)', $fn);
while (<IN>) {
  chomp;
  if ($_ eq '') {
    next;
  }

  my @array = &csvsplit($_, $sep);

  for (my $i=0;$i<@array;$i++) {
    my $len = length($array[$i]);
    my @wide = $array[$i] =~ /([\p{Hani}\p{Halfwidth_And_Fullwidth_Forms}\p{CJKSymbols}])/g;
    $len += (scalar @wide);

    if ($colWid[$i] < $len) {
      $colWid[$i] = $len;
    }
  }
}
close(IN);

my $format = "%-".$colWid[0]."s";
my $split = "-"x$colWid[0];
for (my $i=1;$i<@colWid;$i++) {
  $split .= "-+-".("-"x$colWid[$i]);
  $format .= " | %".$colWid[$i]."s";
}

print "\n";

open(IN,'<:encoding(utf8)', $fn);
while (<IN>) {
  chomp;
  if ($_ eq '') {
    next;
  }

  my @array = &csvsplit($_, $sep);

  for (my $i=0;$i<@array;$i++) {
    if ($i != 0) {
      print ' | ';
    }

    my $len = $colWid[$i];
    my @wide = $array[$i] =~ /([\p{Hani}\p{Halfwidth_And_Fullwidth_Forms}\p{CJKSymbols}])/g;
    $len -= (scalar @wide);

    printf('%'.(($i==0)?'-':'').$len.'s', $array[$i]);
  }
  print "\n";

  if ($. == 1) {
    print $split."\n";
  }
}
close(IN);

print "\n";
