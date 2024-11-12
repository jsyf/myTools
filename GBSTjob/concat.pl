#!/usr/bin/env perl
use strict;

if (!-e 'runs') {
  print 'no runs folder!'."\n";
  exit;
}

my $pwd = $ENV{'PWD'}.'/';

my %sFiles;
opendir(my $fh, $pwd.'runs/');
while (readdir($fh)) {
  if (($_ !~ /^\.+$/) && (-e $pwd.'runs/'.$_.'/rawData/')) {
    my $runID = $_;

    foreach my $dataType ('raw','clean') {
      if (!-e $pwd.'runs/'.$runID.'/'.$dataType.'Data/') { next; }
      opendir(my $fh2, $pwd.'runs/'.$runID.'/'.$dataType.'Data/');
      while (readdir($fh2)) {
        if ($_ !~ /\.fastq\.gz/) {
          next;
        }

        my $fn = $_;
        my @info = split(/[\_\.]+/, $fn);

        $sFiles{$dataType}{$info[0]}{$info[3]}{$runID} = '../../runs/'.$runID.'/'.$dataType.'Data/'.$fn;
      }
      closedir($fh2);
    }
  }
}
closedir($fh);

foreach my $dtType (sort{$a cmp $b} (keys %sFiles)) {
  if (!-e $pwd.'concat/'.$dtType.'Data/') {
    system('mkdir '.$pwd.'concat/'.$dtType.'Data/');
  }
  chdir($pwd.'concat/'.$dtType.'Data/');

  foreach my $sn (sort{$a cmp $b} (keys %{$sFiles{$dtType}})) {
    foreach my $read (sort{$a cmp $b} (keys %{$sFiles{$dtType}{$sn}})) {
      my $outName = $sn.'_'.$read.($dtType eq 'clean'?'.clean':'').'.fastq.gz';

      my $cmd = '';
      my @allRun = sort{$a cmp $b} (keys %{$sFiles{$dtType}{$sn}{$read}});
      if (@allRun == 1) {
        $cmd = 'ln -s '.$sFiles{$dtType}{$sn}{$read}{$allRun[0]}.' ./'.$outName;
      }
      else {
        $cmd = 'cat';
        foreach my $runID (@allRun) {
          $cmd .= ' '.$sFiles{$dtType}{$sn}{$read}{$runID};
        }
        $cmd .= ' > ./'.$outName;
      }

      print $cmd."\n";
      system($cmd);
    }
  }

  chdir($pwd);
}
