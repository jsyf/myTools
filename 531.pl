#!/usr/bin/env perl
use strict;

sub round {
  my $val = shift;
  my $unit = shift;

  my $res = $unit*int(($val/$unit)+0.5);

  return($res);
}

my %fac = (
  '15RM' => 1.64,
  '14RM' => 1.57,
  '13RM' => 1.50,
  '12RM' => 1.44,
  '11RM' => 1.39,
  '10RM' => 1.33,
  '9RM' => 1.29,
  '8RM' => 1.24,
  '7RM' => 1.20,
  '6RM' => 1.16,
  '5RM' => 1.13,
  '4RM' => 1.09,
  '3RM' => 1.06,
  '2RM' => 1.03
);

print 'Training (BenchPress, Deadlift, MilitaryPress or Squat): ';
chomp(my $sport = <STDIN>);

print 'Weight: ';
chomp(my $w = <STDIN>);

print 'Type (1RM, 5RM, etc.): ';
chomp(my $type = <STDIN>);
if ($type !~ /\D/) {$type .= 'RM';}

my $PR = ((uc($type) eq 'PR') || (uc($type) eq '1RM'))?$w:$w*$fac{uc($type)};
my $TM = $PR*0.9;

my @setDef = qw / Set1 Set2 Set3 JokerSet FSL Assist /;
my @weekStart = qw / 0.65 0.7 0.75 0.4 / ;
my @weekRep = qw / 5 3 5 5 / ;

print "\n";
print 'Training: '.$sport."\n";

foreach my $cycle (1..6) {
  foreach my $week (1..4) {
    if (($cycle%2 == 1) && ($week == 4)) {next;}

    if ($week != 4) {
      printf("%-6s", $cycle.'-'.$week);
    }
    else {
      print 'Deload';
    }
    foreach my $set (1..6) {
      my $weightFactor = ($weekStart[$week-1] - 0.1) + (0.1*$set);
      if ($set == 4) {
        $weightFactor = sprintf("%.4f", ($weekStart[$week-1] + 0.2)*1.05);
      }
      elsif (($set == 5) || ($set == 6)) {
        $weightFactor = $weekStart[$week-1];
      }

      #my $weight = ($cycle%2 == 0)?$TM+5:$TM;
      my $weight = $TM;

      my $rep = $weekRep[($week-1)%(scalar @weekRep)];
      if ($week == 3) {
        if ($set <= 3) {
          $rep = 7-(2*$set);
        }
        else {
          $rep = 1;
        }
      }

      #printf(" %6.4f*%d", $weightFactor,$rep);
      printf(" ".chr(27).'[1;31m'."%6.0f".chr(27).'[m'."*".chr(27).'[1;33m'."%d".chr(27).'[m', &round($weightFactor*$weight, 5),$rep);
    }
    print "\n";
  }
  if (($sport eq 'Deadlift') || ($sport eq 'Squat')) {
    $TM += 5;
  }
  elsif (($sport eq 'BenchPress') || ($sport eq 'MilitaryPress')) {
    $TM += 2.5;
  }
}
