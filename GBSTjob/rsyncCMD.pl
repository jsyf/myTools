#!/usr/bin/env perl
use strict;

use Cwd qw / abs_path /;

if (@ARGV < 1) {
  print 'Usage: perl '.$0.' pids'.$/;
  exit;
}

my @pids;
foreach (@ARGV) {
  if ((-e '/mnt/NFS/pisces/projects/'.$_.'/') && ($_ !~ /^\./)) {
    push(@pids, $_);
  }
}

my @server = qw / 111 114 193 194 220 231 / ;

my %queue;
foreach my $pid (@pids) {
  # for FASTQ
  if (-e '/mnt/NFS/pisces/projects/'.$pid.'/FASTQ/concat/') {
    foreach my $type ('raw','clean') {
      my $folder = '/mnt/NFS/pisces/projects/'.$pid.'/FASTQ/concat/'.$type.'Data/';
      if (!-e $folder) {
        next;
      }

      open(IN,'ls '.$folder.' | grep "fastq" | cut -f 1 -d"_" | uniq | ');
      while (<IN>) {
        chomp;
        if ($_ eq '') {
          next;
        }

        push(@{$queue{$pid}{'concat_'.$type}}, $_);
      }
      close(IN);
    }
  }
  else {
    foreach my $type ('raw','clean') {
      my $folder = '/mnt/NFS/pisces/projects/'.$pid.'/FASTQ/'.$type.'Data/';
      if (!-e $folder) {
        next;
      }

      open(IN,'ls '.$folder.' | grep "fastq" | cut -f 1 -d"_" | uniq | ');
      while (<IN>) {
        chomp;
        if ($_ eq '') {
          next;
        }

        push(@{$queue{$pid}{$type}}, $_);
      }
      close(IN);
    }
  }

  # For Analysis
  if (-e '/mnt/NFS/pisces/projects/'.$pid.'/Link/Analysis/') {
    opendir(my $fh, '/mnt/NFS/pisces/projects/'.$pid.'/Link/Analysis/');
    while (readdir($fh)) {
      if ($_ =~ /^\./) {
        next;
      }

      my $pathTmp = '/mnt/NFS/pisces/projects/'.$pid.'/Link/Analysis/'.$_;
      if (-l $pathTmp) {
        my $source = readlink($pathTmp);
        if ($source =~ /^\//) {
          $pathTmp = $source;
        }
        else {
          $pathTmp = abs_path('/mnt/NFS/pisces/projects/'.$pid.'/Link/Analysis/'.$source);
        }
      }

      push(@{$queue{$pid}{'Analysis'}}, $pathTmp);
    }
    closedir($fh);
  }
}

open(OUT,'>dl.sc');
foreach my $pid (sort{$a cmp $b} (keys %queue)) {
  foreach my $prefix ('', 'concat_') {
    if (!defined($queue{$pid}{$prefix.'raw'}) && !defined($queue{$pid}{$prefix.'clean'})) {
      next;
    }

    foreach my $type ('raw','clean') {
      if (!defined($queue{$pid}{$prefix.$type}) || ((scalar (@{$queue{$pid}{$prefix.$type}})) == 0)) {
        next;
      }

      print OUT 'if ! [ -e '.$pid.'/FASTQ/'.$prefix.$type.'Data/ ]; then mkdir -p '.$pid.'/FASTQ/'.$prefix.$type.'Data/; fi'.$/;
    }

    print OUT 'if ! [ -e '.$pid.'/FASTQ/'.$prefix.'reports/ ]; then mkdir -p '.$pid.'/FASTQ/'.$prefix.'reports/; fi'.$/;
  }
  if (defined($queue{$pid}{'Analysis'})) {
    print OUT 'if ! [ -e '.$pid.'/Analysis/ ]; then mkdir -p '.$pid.'/Analysis/; fi'.$/;
  }
}
close(OUT);

my %out;
foreach my $sv (@server) {
  open($out{$sv}, '>dl_'.$sv.'.sc');
}
my $i = 0;
foreach my $pid (sort{$a cmp $b} (keys %queue)) {
  foreach my $concat (0,1) {
    if (!defined($queue{$pid}{(($concat == 1)?'concat_':'').'raw'}) && !defined($queue{$pid}{(($concat == 1)?'concat_':'').'clean'})) {
      next;
    }

    foreach my $type ('raw','clean') {
      if (!defined($queue{$pid}{(($concat == 1)?'concat_':'').$type}) || ((scalar (@{$queue{$pid}{(($concat == 1)?'concat_':'').$type}})) == 0)) {
        next;
      }

      foreach my $sn (@{$queue{$pid}{(($concat == 1)?'concat_':'').$type}}) {
        print {$out{$server[($i%6)]}} 'rsync -avLP --size-only jsyf@192.168.1.'.$server[($i%6)].':/mnt/NFS/pisces/projects/'.$pid.'/FASTQ/'.(($concat == 1)?'concat/':'').$type.'Data/'.$sn.'_* ./'.$pid.'/FASTQ/'.(($concat == 1)?'concat_':'').$type.'Data/'.$/;
        $i ++;
      }
      print {$out{$server[($i%6)]}} 'rsync -avLP --size-only jsyf@192.168.1.'.$server[($i%6)].':/mnt/NFS/pisces/projects/'.$pid.'/FASTQ/'.(($concat == 1)?'concat/':'').$type.'Data/md5* ./'.$pid.'/FASTQ/'.(($concat == 1)?'concat_':'').$type.'Data/'.$/;
      $i ++;
    }

    print {$out{$server[($i%6)]}} 'rsync -avLP --size-only jsyf@192.168.1.'.$server[($i%6)].':/mnt/NFS/pisces/projects/'.$pid.'/FASTQ/'.(($concat == 1)?'concat/':'').'reports/* ./'.$pid.'/FASTQ/'.(($concat == 1)?'concat_':'').'reports/'.$/;
    $i ++;
  }

  if (defined($queue{$pid}{'Analysis'})) {
    foreach my $fn (@{$queue{$pid}{'Analysis'}}) {
      print {$out{$server[($i%6)]}} 'rsync -avLP --size-only jsyf@192.168.1.'.$server[($i%6)].':'.$fn.' ./'.$pid.'/Analysis/'.$/;
      $i ++;
    }
  }
}
foreach my $sv (@server) {
  close($out{$sv});
}
