#!/usr/bin/env perl
use strict;

my @header;
my $n = 0;
while (<>) {
  chomp;
  if ($_ =~ /^#/) {
    @header = split("\t", substr($_, 1));
    next;
  }

  my @array = split("\t", $_);

  for (my $i=0;$i<@array;$i++) {
    my @list;
    if ($i == 7) {
      @list = split(";", $array[$i]);
    }
    elsif ($i == 8 || $i == 9) {
      @list = split(":", $array[$i]);
    }
    else {
      print $header[$i]."\t".$array[$i]."\n";
      next;
    }

    print $header[$i]."\n";

    foreach my $j (@list) {
      print "\t".$j."\n";
    }
  }

  print "--\n";

  $n ++;

  if ($n > 5) {last;}
}
