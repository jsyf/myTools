#!/usr/bin/env perl
use strict;

foreach my $i (0..5) {
  foreach my $bgColor (0..7) {
    print $i."\tbg:".$bgColor."\t".(($i+$bgColor != 0)?chr(27).'['.(($i != 0)?$i.';':'').(($bgColor != 0)?'4'.$bgColor:'').'m':'');

    print 'NA';

    foreach my $fgColor (0..7) {
      print chr(27)."[3".$fgColor."m3".$fgColor;
    }
    print chr(27)."[m\n";
  }
}
