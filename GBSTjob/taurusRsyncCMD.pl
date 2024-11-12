#!/usr/bin/env perl
use strict;

use Cwd qw / abs_path /;

if (@ARGV < 1) {
  print 'Usage: perl '.$0.' pids'.$/;
  exit;
}

my @pids;
foreach (@ARGV) {
  if ((-e '/mnt/NFS/taurus/archived/2023/'.$_.'/') && ($_ !~ /^\./)) {
    push(@pids, $_);
  }
}

my @server = qw / 111 114 193 194 220 231 / ;
@server = reverse(@server);

my %queue;
foreach my $pid (@pids) {
  # for FASTQ
  foreach my $type ('raw','clean') {
    my $folder = '/mnt/NFS/taurus/archived/2023/'.$pid.'/FASTQ/'.$type.'Data/';
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

  # For Analysis
  if (-e '/mnt/NFS/taurus/archived/2023/'.$pid.'/Link/Analysis/') {
    opendir(my $fh, '/mnt/NFS/taurus/archived/2023/'.$pid.'/Link/Analysis/');
    while (readdir($fh)) {
      if ($_ =~ /^\./) {
        next;
      }

      my $pathTmp = '/mnt/NFS/taurus/archived/2023/'.$pid.'/Link/Analysis/'.$_;
      if (-l $pathTmp) {
        my $source = readlink($pathTmp);
        if ($source =~ /^\//) {
          $pathTmp = $source;
        }
        else {
          $pathTmp = abs_path('/mnt/NFS/taurus/archived/2023/'.$pid.'/Link/Analysis/'.$source);
        }
      }

      push(@{$queue{$pid}{'Analysis'}}, $pathTmp);
    }
    closedir($fh);
  }
}

open(OUT,'>taurus_dl.sc');
foreach my $pid (sort{$a cmp $b} (keys %queue)) {
  foreach my $type ('raw','clean') {
    if (!defined($queue{$pid}{$type}) || ((scalar (@{$queue{$pid}{$type}})) == 0)) {
      next;
    }

    print OUT 'if ! [ -e '.$pid.'/FASTQ/'.$type.'Data/ ]; then mkdir -p '.$pid.'/FASTQ/'.$type.'Data/; fi'.$/;
  }
  print OUT 'if ! [ -e '.$pid.'/FASTQ/reports/ ]; then mkdir -p '.$pid.'/FASTQ/reports/; fi'.$/;
  if (defined($queue{$pid}{'Analysis'})) {
    print OUT 'if ! [ -e '.$pid.'/Analysis/ ]; then mkdir -p '.$pid.'/Analysis/; fi'.$/;
  }
}
close(OUT);

my %out;
foreach my $sv (@server) {
  open($out{$sv}, '>taurus_dl_'.$sv.'.sc');
}
my $i = 0;
foreach my $pid (sort{$a cmp $b} (keys %queue)) {
  foreach my $type ('raw','clean') {
    if (!defined($queue{$pid}{$type}) || ((scalar (@{$queue{$pid}{$type}})) == 0)) {
      next;
    }

    foreach my $sn (@{$queue{$pid}{$type}}) {
      print {$out{$server[($i%6)]}} 'rsync -avLP -size-only jsyf@192.168.1.'.$server[($i%6)].':/mnt/NFS/taurus/archived/2023/'.$pid.'/FASTQ/'.$type.'Data/'.$sn.'_* ./'.$pid.'/FASTQ/'.$type.'Data/'.$/;
      $i ++;
    }
    print {$out{$server[($i%6)]}} 'rsync -avLP -size-only jsyf@192.168.1.'.$server[($i%6)].':/mnt/NFS/taurus/archived/2023/'.$pid.'/FASTQ/'.$type.'Data/md5* ./'.$pid.'/FASTQ/'.$type.'Data/'.$/;
    $i ++;
  }
  print {$out{$server[($i%6)]}} 'rsync -avLP -size-only jsyf@192.168.1.'.$server[($i%6)].':/mnt/NFS/taurus/archived/2023/'.$pid.'/FASTQ/reports/* ./'.$pid.'/FASTQ/reports/'.$/;
  $i ++;

  if (defined($queue{$pid}{'Analysis'})) {
    foreach my $fn (@{$queue{$pid}{'Analysis'}}) {
      print {$out{$server[($i%6)]}} 'rsync -avLP -size-only jsyf@192.168.1.'.$server[($i%6)].':'.$fn.' ./'.$pid.'/Analysis/'.$/;
      $i ++;
    }
  }
}
foreach my $sv (@server) {
  close($out{$sv});
}
