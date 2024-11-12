#!/usr/bin/env perl
use strict;

my $n = (@ARGV > 0) ? shift : 10 ;
my $cmdFile = (@ARGV > 0) ? shift : '-';

my $nl = 0;
my @cmds;
open(IN,'<'.$cmdFile);
while (<IN>) {
  chomp;
  if ($_ eq '') {
    next;
  }

  push(@{$cmds[$nl%$n]},$_);
  $nl ++
}
close(IN);

for (my $i=0;$i<@cmds;$i++) {
  if (fork() == 0) {
    foreach my $cmd (@{$cmds[$i]}) {
      print $cmd."\n";
      system($cmd);
      #sleep 1
    }
    exit;
  }
}

wait for 0 .. $n;
