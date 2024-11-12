#!/usr/bin/perl
use strict;

my @folders;
open(IN,'ls -d compare_* | grep -v "6.bk" | ');
while (<IN>) {
  chomp;
  if ($_ eq '') {
    next;
  }

  if (-e $_) {
    push(@folders,$_);
  }
}
close(IN);

chomp(my $pwd = `pwd`);
if (substr($pwd,-1) ne '/') {
  $pwd .= '/';
}

open(SH,'>plot3A.sh');
foreach my $folder (@folders) {
  chdir($folder);

  if (!-e 'all3A') {
    mkdir('all3A');
  }

  chdir('all3A');

  my @header;
  my @coreMap;
  my %envPara;
  open(IN,'<../data/Mapping.txt');
  while (<IN>) {
    chomp;
    if ($_ eq '') {
      next;
    }

    if ($. == 1) {
      @header = split("\t",$_);

      my @coreHeader = @{\@header}[0..4];

      push(@coreMap,\@coreHeader);
    }
    else {
      my @array = split("\t",$_);

      my $sampleName = $array[0];
      my @coreContent = @{\@array}[0..4];

      push(@coreMap,\@coreContent);

      for (my $i=5;$i<@array;$i++) {
        if (!defined($array[$i])) {
          next;
        }

        $envPara{$header[$i]}{$sampleName} = $array[$i];
      }
    }
  }
  close(IN);

  for (my $i=5;$i<@header;$i++) {
    if (!defined($header[$i])) {
      next;
    }

    my $env = $header[$i];
    if (!-e $env) {
      mkdir($env);
    }

    open(OUT,'>'.$env.'/Mapping_'.$env.'.txt');
    for (my $j=0;$j<@coreMap;$j++) {
      if ($j == 0) {
        print OUT join("\t",@{$coreMap[$j]},$env)."\n";
      }
      else {
        print OUT join("\t",@{$coreMap[$j]},$envPara{$env}{$coreMap[$j][0]})."\n";
      }
    }
    close(OUT);

    print SH 'plot_3A.pl '.$folder.'/'.'D.1_taxa_summary/otu_table.greengenesID_L7.txt '.$folder.'/all3A/'.$env.'/Mapping_'.$env.'.txt'.' \'Species\' \''.$folder.'/all3A/'.$env.'\''."\n";;
  }

  chdir('../../');
}
close(SH);
