#!/usr/bin/env perl
use strict;

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

my @table;
open(IN,'<'.$fn);
while (<IN>) {
  chomp;
  my @array = &csvsplit($_, $sep);

  for (my $c=0;$c<@array;$c++) {
    $table[$c][$.-1] = $array[$c];
  }
}
close(IN);

foreach my $row (@table) {
  print join("\t",@{$row})."\n";
}
