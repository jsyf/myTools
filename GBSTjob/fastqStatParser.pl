#!/usr/bin/env perl
use strict;

if (@ARGV < 1) {
  print "Usage: perl $0 fastq_stat_folder\n";
  exit;
}

my $folder = shift;
$folder =~ s/\/+$//;

if ((!-e $folder) || (!-d $folder)) {
  print "Usage: perl $0 fastq_stat_folder\n";
  exit;
}

my @files;
opendir(my $fh, $folder);
while (readdir($fh)) {
  if ($_ =~ /(.+)\.fastq-stats\.txt/) {
    my $pre = $1;
    if ($pre !~ /.fastq$/) {
      $pre .= '.fastq';
    }
    if ($pre !~ /.gz$/) {
      $pre .= '.gz';
    }

    push(@files,[$_,$pre]);
  }
}
closedir($fh);

my %colTrans = (
  'reads' => 'Read_Counts',
  'len mean' => 'Length_Mean',
  'phred' => 'Phred',
  'qual mean' => 'Qual_Mean',
  '%Q20' => 'Q20_Ratio',
  '%Q30' => 'Q30_Ratio',
  '%GC' => 'GC',
  'total bases' => 'Total_Bases',
);

my %table;
foreach my $row (@files) {
  my ($file,$pre) = @{$row};

  if (!-e $folder.'/'.$file) {
    next;
  }

  my $fileName = $pre;
  open(IN,'<'.$folder.'/'.$file);
  while (<IN>) {
    chomp;
    if ($_ eq '') {
      next;
    }

    my ($col, $val) = split("\t",$_);

    if (defined($colTrans{$col}) && ($colTrans{$col} ne '')) {
      $table{$fileName}{$colTrans{$col}} = $val;
    }
    elsif ($col eq 'len min') {
      $table{$fileName}{'Length'}[0] = $val;
    }
    elsif ($col eq 'len max') {
      $table{$fileName}{'Length'}[1] = $val;
    }
  }
  close(IN);
}

my @cols = ('GC','Length','Length_Mean','Phred','Q20_Ratio','Q30_Ratio','Qual_Mean','Read_Counts','Total_Bases');

open(OUT,'>'.$folder.'/summary.csv');
print OUT join(',','File_Name',@cols)."\n";
foreach my $fileName (sort{$a cmp $b} (keys %table)) {
  print OUT $fileName;

  foreach my $col (@cols) {
    my $val = '';

    if ($col eq 'Length') {
      $val = $table{$fileName}{$col}[0].'-'.$table{$fileName}{$col}[1];
    }
    else {
      $val = $table{$fileName}{$col};
    }

    print OUT ','.$val;
  }

  print OUT "\n";
}
close(OUT);
