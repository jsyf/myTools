#!/usr/bin/env perl
use strict;

if (@ARGV != 4) {
  print 'Usage: perl '.$0.' projectID level[total/sample] type[read/base] cutoff'."\n";
  exit;
}

my $pid = shift;
my $lvl = shift;
my $type = shift;
my $cut = shift;

if ($lvl !~ /^(total|sample)$/) {
  print 'level: total/sample'."\n";
  exit;
}

if ($type !~ /^(read|base)$/) {
  print 'type: read/base'."\n";
  exit;
}

if ($cut =~ /^(\d+)([KMGT])$/) {
  my $val = $1;
  my $unit = $2;

  if ($unit eq 'K') {
    $cut = $val * 1000;
  }
  elsif ($unit eq 'M') {
    $cut = $val * 1000000;
  }
  elsif ($unit eq 'G') {
    $cut = $val * 1000000000;
  }
  elsif ($unit eq 'T') {
    $cut = $val * 1000000000000;
  }

  undef($val);
  undef($unit);
}
elsif ($cut =~ /\D/) {
  print 'cutoff: only integer'."\n";
  exit;
}

open(IN,'perl /mnt/NFS/EC2480U-P/jsyf_tmp/jsyf_self/findProject.pl '.(($pid =~ /:/)?$pid:'Simple:'.$pid).' | ');
while (<IN>) {
  chomp;
  if ($_ eq '') {
    next;
  }

  my $line = $_;
  my @array = split(/\s{2,}/, $line);

  if (@array > 3) {
    my $target = '';
    if ($type eq 'read') {
      $target = $array[2];
    }
    elsif ($type eq 'base') {
      $target = $array[3];
    }

    if ($lvl eq 'sample') {
      if ($target !~ /\D/) {
        if ($target < $cut*0.9) {
          $line =~ s/${target}/\033[1;31m${target}\033[m/;
        }
        elsif ($target < $cut) {
          $line =~ s/${target}/\033[1;33m${target}\033[m/;
        }
      }
    }
    elsif ($lvl eq 'total') {
      if (($array[1] eq 'Total') && ($target =~ / /))  {
        my ($val, $unit) = split(' ', $target);

        if ($unit eq 'K') {
          $val *= 1000;
        }
        elsif ($unit eq 'M') {
          $val *= 1000000;
        }
        elsif ($unit eq 'G') {
          $val *= 1000000000;
        }
        elsif ($unit eq 'T') {
          $val *= 1000000000000;
        }

        if ($val < $cut*0.9) {
          $line =~ s/${target}/\033[1;31m${target}\033[m/;
        }
        elsif ($val < $cut) {
          $line =~ s/${target}/\033[1;33m${target}\033[m/;
        }

      }
    }
  }

  print $line."\n";
}
close(IN);
