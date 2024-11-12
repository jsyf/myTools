#!usr/bin/env perl
use strict;

system('screen -ls');

print "\n";

my @id;
open(IN,'screen -ls | grep "De" | ');
while (<IN>) {
  chomp;
  if ($_ eq '') {
    next;
  }

  my @array = split(/[\s\.\(\)]+/,$_);

  push(@id,$array[1]);
}
close(IN);

print join(" ; ",map {'screen -r '.$_} (@id))."\n";
