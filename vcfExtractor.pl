#!/usr/bin/env perl
use strict;

use Text::ParseWords;

if (@ARGV < 2) {
  print 'Usage: perl '.$0.' inputVCF outputPrefix [lineNumber]'.$/;
  exit;
}

my $fn = $ARGV[0];
my $outFn  = $ARGV[1].'_table.txt';
my $infoFn = $ARGV[1].'_info.txt';
my $lineNumber = (@ARGV == 3) ? $ARGV[2] : -1;

if (($lineNumber != -1) && ($lineNumber =~ /\D/)) {
  print 'Invalid lineNumber: '.$lineNumber."\n";
  exit;
}

my %metaInfo;
my @header;
my %headerIdx;
my %data;
my %colOrder;
open(OUT, '>'.$outFn);
open(IN, 'bgzip -cd '.$fn.(($lineNumber != -1)?' | head -n '.$lineNumber:'').' | ');
while (<IN>) {
  chomp;
  $_ =~ s/[\r\n]+$//;
  if ($_ eq '') {
    next;
  }

  if ($_ =~ /^##([A-Z]+)=<(.+)>\s*$/) { # For Meta-information lines -> Information field format
    my ($field, $def) = ($1, $2);

    my @defs = parse_line(',', 1, $def);

    #print $field."\n";

    my $id = '';
    my %thisDef;
    foreach my $dd (@defs) {
      my ($key, $val) = split('=', $dd, 2);

      if ($val =~ /^\s*\".*\"\s*$/) {
        $val =~ s/^\s*\"\s*//;
        $val =~ s/\s*\"\s*$//;
      }

      #print "\t".$key.': '.$val."\n";

      if ($key eq 'ID') {
        $id = $val;
      }
      else {
        $thisDef{$key} = $val;
        # Keys in INFO: [ID, Type, Number, Description, Source, Version]
        #   Type: one of [Integer, Float, Flag, Character, and String]
        #   Number: number of values
        #     Number=A, values for each Alternate allele
        #     Number=R, values for reference allele and each Alternate alleli
        #     Number=G, values for each genotype
        #     Number=., value rule unknown
        # Keys in FILTER: [ID, Description]
        # Keys in FORMAT: [ID, Type, Number, Description]
        #   Type: one of [Integer, Float, Character, and String]
        #   Number: number of values
        # Keys in ALT: [ID, Description]
      }
    }
    
    #print "--\n";
    if (!defined($metaInfo{$field}) || !defined($metaInfo{$field}{$id})) {
      $metaInfo{$field}{$id} = \%thisDef;
      push(@{$colOrder{$field}}, $id);
    }
    else {
      print join(' ', $field, $id, 'exists!')."\n";
    }
  }
  elsif ($_ =~ /^##/) {
    #print 'Other header: '."\n\t".$_."\n";
    next;
  }
  elsif ($_ =~ /^#/) {
    @header = split("\t", $');
    for (my $i=0;$i<@header;$i++) {
      $headerIdx{$header[$i]} = $i;
    }

    print OUT join("\t", qw / Chromosome PositionStart PositionEnd vcfID Ref Alt vcfQuality / );
    foreach my $colInInfo (@{$colOrder{'INFO'}}) {
      print OUT "\t".'INFO:'.$colInInfo;
    }
    foreach my $colInFormat (@{$colOrder{'FORMAT'}}) {
      print OUT "\t".'Sample:'.$colInFormat;
    }
    print OUT "\n";

    open(INFO, '>'.$infoFn);
    print INFO join("\t", qw / Colname Field ID Type Number Description Source Version / )."\n";
    foreach my $field (qw / INFO FORMAT / ) {
      foreach my $id ((@{$colOrder{$field}})) {
        print INFO join("\t", (($field eq 'FORMAT')?'Sample':$field).':'.$id, $field, $id);

        foreach my $col (qw / Type Number Description Source Version /) {
          my $val = '--';
          if (defined($metaInfo{$field}{$id}{$col})) {
            $val = $metaInfo{$field}{$id}{$col};
          }

          print INFO "\t".$val;
        }

        print INFO "\n";
      }
    }
    close(INFO);
  }
  else {
    my @array = split("\t", $_);
#print 'This line: '.$_."\n";

    my %out;

    $out{'Chromosome'} = $array[$headerIdx{'CHROM'}];
    $out{'PositionStart'} = $array[$headerIdx{'POS'}];
    $out{'vcfID'} = $array[$headerIdx{'ID'}];
    $out{'Ref'} = $array[$headerIdx{'REF'}];
    $out{'Alt'} = $array[$headerIdx{'ALT'}];
    $out{'vcfQuality'} = $array[$headerIdx{'QUAL'}];

    my $infoStr = $array[$headerIdx{'INFO'}];
    my $formatStr = $array[$headerIdx{'FORMAT'}];
    my $sampleStr = $array[9];

    $out{'PositionEnd'} = $out{'PositionStart'} + length($out{'Ref'}) - 1;
    my @infoArray = parse_line(';', 1, $infoStr);
    my @formatArray = parse_line(':', 1, $formatStr);
    my @sampleArray = parse_line(':', 1, $sampleStr);

    # for INFO
    foreach my $infoEle (@infoArray) {
      my ($key, $val) = split('=', $infoEle, 2);

      if ($val eq '') {
        # Flag type
        $val = 'True';
      }
      elsif ($val =~ /^\s*\".+\"\s*$/) {
        $val =~ s/^\s*\"//;
        $val =~ s/\"\s*$//;
      }

      $out{'INFO'}{$key} = $val;
    }

    # for format and sample
    for (my $i=0;$i<@formatArray;$i++) {
      $out{'Sample'}{$formatArray[$i]} = $sampleArray[$i];
    }

    # export
    print OUT join("\t", @{\%out}{qw / Chromosome PositionStart PositionEnd vcfID Ref Alt vcfQuality / });
    foreach my $colInInfo (@{$colOrder{'INFO'}}) {
      print OUT "\t".$out{'INFO'}{$colInInfo};
    }
    foreach my $colInFormat (@{$colOrder{'FORMAT'}}) {
      print OUT "\t".$out{'Sample'}{$colInFormat};
    }
    print OUT "\n";
  }
}
close(IN);
close(OUT);
