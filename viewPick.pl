#!/usr/bin/env perl
use strict;

use Text::ParseWords qw / parse_line /;
use utf8;
binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
use open ':encoding(UTF-8)';

my @table;
my @header;
my @colWidth;

while (<>) {
  chomp;

  if ($. == 1) {
    $_ =~ s/^\x{FEFF}//;
  }

  my @array = parse_line("\t", 0, $_);

  if ($. == 1) {
    @header = @array;
    push(@table, \@header);
  }
  else {
    push(@table, \@array);
  }

  for (my $i=0;$i<@array;$i++) {
    my $len = length($array[$i]);
    my @wide = $array[$i] =~ /([\p{Hani}\p{Halfwidth_And_Fullwidth_Forms}\p{CJKSymbols}])/g;
    $len += (scalar @wide);

    if ($colWidth[$i] < $len) {
      $colWidth[$i] = $len;
    }
  }
}

my $pattern = "| %-".$colWidth[0]."s";
my $split = "| :".("-"x($colWidth[0]-1));

for (my $i=1;$i<@colWidth;$i++) {
  $pattern .= " | %".$colWidth[$i]."s";
  $split .= " | ".("-"x($colWidth[$i]-1)).":";
}

$pattern .= " |\n";
$split .= " |\n";

for (my $nl=0;$nl<@table;$nl++) {
  my @array = @{$table[$nl]};

  for (my $i=0;$i<@array;$i++) {
    if ($i != 0) {
      print ' ';
    }

    my $len = $colWidth[$i];
    my @wide = $array[$i] =~ /([\p{Hani}\p{Halfwidth_And_Fullwidth_Forms}\p{CJKSymbols}])/g;
    $len -= (scalar @wide);

    printf('| %'.(($i==0)?'-':'').$len.'s', $array[$i]);
  }

  print " |\n";

  if ($nl == 0) {
    print $split;
  }
}

=h
printf($pattern, @header);
print $split;

foreach my $row (@table) {
  printf($pattern, @{$row});
}

=cut
