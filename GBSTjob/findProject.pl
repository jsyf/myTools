#!/usr/bin/env perl

package projects;

sub findRelatedProjectPath {
  # Find all related project ID and their path, test project ID with different suffix
  # Input: project ID
  # Output: 
  #   hash:
  #     Keys: all founded project ID, string
  #     Values: path of each project, string
  my $pid = shift;
  my %results;
  foreach my $suf ('', '-re', '-re1', '-re2', '-re3', '-P', '-NG') {
    if (-e '/mnt/NFS/EC2480U-P/scratch/QCResults/fastq/'.$pid.$suf.'/') {
      #$results{$pid.$suf} = 'EC24P';
      $results{$pid.$suf} = '/mnt/NFS/EC2480U-P/scratch/QCResults/fastq/'.$pid.$suf.'/';
    }
    elsif (-e '/mnt/NFS/BioBankPool/archived/2020/'.$pid.$suf.'/') {
      #$results{$pid.$suf} = 'BioBank-2020';
      $results{$pid.$suf} = '/mnt/NFS/BioBankPool/archived/2020/'.$pid.$suf.'/';
    }
    elsif (-e '/mnt/NFS/pisces/projects/'.$pid.$suf.'/FASTQ/IQC/') {
      #$results{$pid.$suf} = 'pisces-outsourced';
      $results{$pid.$suf} = '/mnt/NFS/pisces/projects/'.$pid.$suf.'/FASTQ/IQC/';
    }
    elsif (-e '/mnt/NFS/pisces/projects/'.$pid.$suf.'/FASTQ/concat/') {
      #$results{$pid.$suf} = 'pisces-concat';
      $results{$pid.$suf} = '/mnt/NFS/pisces/projects/'.$pid.$suf.'/FASTQ/concat/';
    }
    elsif (-e '/mnt/NFS/pisces/projects/'.$pid.$suf.'/FASTQ/') {
      #$results{$pid.$suf} = 'pisces';
      $results{$pid.$suf} = '/mnt/NFS/pisces/projects/'.$pid.$suf.'/FASTQ/';
    }
    elsif ((-e '/mnt/NFS/pisces/projects/'.$pid.$suf.'/Data/') && (index($pid, 'OL') == 0)) {
      #$results{$pid.$suf} = 'pisces';
      $results{$pid.$suf} = '/mnt/NFS/pisces/projects/'.$pid.$suf.'/Data/';
    }
  }

  return(%results);
}

sub fastqType {
  # Find existing data type
  # Input:
  #   1. project ID
  #   2. Result from findRelatedProjectPath
  # Output:
  #   array:
  #     valid data type in the order of [raw, clean]
  my $pid = shift;
  my $path = shift;

  my @result;
  foreach my $type ('raw', 'clean') {
    if (-e $path.$type.'Data/') {
      push(@result, $type);
    }
  }

  return(@result);
}

sub getSampleStats {
  # Get fastq stats of query project ID
  my $pid = shift;
  my $path = shift;
  my $type = shift;

  my %results; # SampleName -> ['ReadPairs', 'TotalBases', 'Reads' -> ['R1', 'R2', 'R3']]

  my @stats;
  if (-e $path.'demux_reports/fastq-stats_'.$type.'/summary.csv') {
    push(@stats, $path.'demux_reports/fastq-stats_'.$type.'/summary.csv');
  }
  elsif (-e $path.'reports/fastq-stats_'.$type.'/summary.csv') {
    push(@stats, $path.'reports/fastq-stats_'.$type.'/summary.csv');
  }
  else {
    my $tmpPath = $path;
    $tmpPath =~ s/concat\/?.*/runs\//;
    opendir($statFH, $tmpPath);
    while (readdir($statFH)) {
      if ($_ =~ /^\.+$/) { next; }
      if (-e $tmpPath.$_.'/reports/fastq-stats_'.$type.'/summary.csv') {
        push(@stats, $tmpPath.$_.'/reports/fastq-stats_'.$type.'/summary.csv');
      }
    }
    closedir($statFH);

    undef($tmpPath);
    undef($statFH);
  }
#print $pid."\t".$type."\n  ".join("\n  ", @stats)."\n";
  foreach my $statSummary (@stats) {
    my %colIdx = (
      'File_Name' => 0,
      'Total_Bases' => 1,
      'Qual_Mean' => 4,
#      'Q20_Ratio' => 5,
      'Q30_Ratio' => 6,
#      'Length_Mean' => 8,
      'Reads' => 9
    );

    open(IN,'<'.$statSummary);
    while (<IN>) {
      chomp;
      if ($_ eq '') {
        next;
      }

      my @array = split(',', $_);

      if ($. == 1) {
        for (my $i=0;$i<@array;$i++) {
          if (defined($colIdx{$array[$i]})) {
            $colIdx{$array[$i]} = $i;
          }
        }
        next;
      }

      my $fn = $array[$colIdx{'File_Name'}];
      my @info = split('_', @{[split(/\./, $fn)]}[0]);
      my $read = pop(@info);
      my $lane = pop(@info);
      my $cell = pop(@info);
      my $sn = join('_', @info);

      if ($fn =~ /^(.+)_[^_]+_(L\d+)_([IR]\d)(\.fastq|\.clean\.fastq)\.gz/) { # GBST format
        $sn = $1;
        $lane = $2;
        $read = $3;
      }
      elsif ($fn =~ /^(.+)_[^_]+_([IR]\d)(\.fastq|\.clean\.fastq)\.gz/) { # GBST lane-merge format
        $sn = $1;
        $read = $2;
      }
      elsif ($fn =~ /(.+)_([IR]\d)(\.fastq|\.clean\.fastq)\.gz/) { # GBST concat format
        $sn = $1;
        $lane = '';
        $read = $2;
      }
      elsif ($fn =~ /(.+)_(S\d+)_(L\d+)_([IR]\d)_\d+\./) { # basespace format
        $sn = $1;
        $lane = $3;
        $read = $4;
      }

      $results{$sn}{$read} += $array[$colIdx{'Reads'}];
      if ($read eq 'R1') {
        $results{$sn}{'ReadPairs'} += $array[$colIdx{'Reads'}];
      }
      if ($read =~ /R[12]/) {
        $results{$sn}{'TotalBases'} += $array[$colIdx{'Total_Bases'}];
        $results{$sn}{'QSum_'.$read} += $array[$colIdx{'Total_Bases'}] * $array[$colIdx{'Qual_Mean'}];
        $results{$sn}{'Q30Base_'.$read} += $array[$colIdx{'Total_Bases'}] * $array[$colIdx{'Q30_Ratio'}];
        $results{$sn}{'Bases_'.$read} += $array[$colIdx{'Total_Bases'}];
      }
      #print join(' ', $sn, 'QSum_'.$read, $array[$colIdx{'Total_Bases'}], $array[$colIdx{'Qual_Mean'}], $results{$sn}{'QSum_'.$read}, $array[$colIdx{'Q30_Ratio'}], $results{$sn}{'Q30Base_'.$read})."\n";
    }
    close(IN);
  }
  return(%results);
}

sub combineResult {
  my %resultOut;
  foreach (@_) {
    my %thisResult = %{$_};

    foreach my $sn (keys %thisResult) {
      foreach my $col (keys %{$thisResult{$sn}}) {
        $resultOut{$sn}{$col} += $thisResult{$sn}{$col};
      }
    }
  }

  return(%resultOut);
}

sub showResult {
  use List::Util qw/ min max /;

  my $pid = shift;
  my $type = shift;
  my %results = %{shift()};
  my @samples = sort{$a cmp $b} (keys %results);
  my $detail = 0;
  if (@_ > 0) {
    $detail = shift;
  }

  my @cols = qw / SampleName ReadPairs TotalBases R1 R2 R3 /;
  if ($detail == 1) {
    foreach my $colA ('QMean', 'Q30') {
      my $colA_inRes = ($colA eq 'QMean')?'QSum':(($colA eq 'Q30')?'Q30Base':$colA);
      foreach my $colB ('R1', 'R2', 'R3') {
        push(@cols, $colA.'_'.$colB);

        foreach my $sn (@samples) {
          if (!defined($results{$sn}{$colA_inRes.'_'.$colB})) {
            next;
          }

          my $val = $results{$sn}{$colA_inRes.'_'.$colB}/$results{$sn}{'Bases_'.$colB};
          $results{$sn}{$colA.'_'.$colB} = sprintf("%.4f", $val);
        }
      }
    }
  }
  my %colLen;
  my %transpose;
  my %validCol;
  foreach my $col (@cols) {
    $colLen{$col} = length($col);
    if ($colLen{$col} < 8) {
      $colLen{$col} = 8;
    }
  }
  foreach my $sn (@samples) {
    if (length($sn) > $colLen{'SampleName'}) {
      $colLen{'SampleName'} = length($sn);
    }

    foreach my $col (@cols[1..$#cols]) {
      if (defined($results{$sn}{$col})) {
        $validCol{$col} = 1;
        push(@{$transpose{$col}}, $results{$sn}{$col});
        if (length($results{$sn}{$col}) > $colLen{$col}) {
          $colLen{$col} = length($results{$sn}{$col});
        }
      }
    }
  }
  $colLen{'SampleName'} = 0 - $colLen{'SampleName'};
  $validCol{'SampleName'} = 1;

  print $pid."\n";
  print '  '.$type."\n";
  print '    ';
  foreach my $col (@cols) {
    if (!defined($validCol{$col})) {
      next;
    }
    if ($col ne 'SampleName') {
      print '  ';
    }
    printf("%".$colLen{$col}."s", $col);
  }
  print "\n";
  foreach my $sn (@samples) {
    print '    ';
    foreach my $col (@cols) {
      if (!defined($validCol{$col})) {
        next;
      }
      if ($col ne 'SampleName') {
        print '  ';
        printf("%".$colLen{$col}."s", $results{$sn}{$col});
      }
      else {
        printf("%".$colLen{$col}."s", $sn);
      }
    }
    print "\n";
  }
  print '    -'."\n";
  foreach my $valType ('Min.', 'Mean', 'Max.', 'Total') {
    print '  ';
    foreach my $col (@cols) {
      if (!defined($validCol{$col})) {
        next;
      }

      if ($col eq 'SampleName') {
        printf("  %".$colLen{$col}."s", $valType);
      }
      else {
        my $value;
        if ($valType eq 'Min.') {
          $value = min @{$transpose{$col}};
        }
        elsif ($valType eq 'Mean') {
          $value = &mean(@{$transpose{$col}});
        }
        elsif ($valType eq 'Max.') {
          $value = max @{$transpose{$col}};
        }
        elsif ($valType eq 'Total') {
          $value = &sum(@{$transpose{$col}});
        }

        if ($value > 1000000000000) {
          $value = sprintf("%.2f T", $value / 1000000000000);
        }
        elsif ($value > 1000000000) {
          $value = sprintf("%.2f G", $value / 1000000000);
        }
        elsif ($value > 1000000) {
          $value = sprintf("%.2f M", $value / 1000000);
        }
        elsif ($value > 1000) {
          $value = sprintf("%.2f K", $value / 1000);
        }
        else {
          $value = sprintf("%.4f", $value);
        }

        if (($col =~ /^Q(Mean|30)_/) && ($valType =~ /^(Mean|Total)$/)) {
          printf("  %".$colLen{$col}."s", '--');
        }
        else {
          printf("  %".$colLen{$col}."s", $value);
        }
      }
    }
    print "\n";
  }
  print '=='."\n";
}

sub sum {
  my $sum = 0;
  foreach (@_) {
    if ($_ =~ /[^\d\.]/) {
      next;
    }
    $sum += $_;
  }
  return($sum);
}
sub mean {
  my $sum = 0;
  my $n = 0;
  foreach (@_) {
    if ($_ =~ /[^\d\.]/) {
      next;
    }
    $sum += $_;
    $n ++;
  }

  my $mean = $sum / $n;
  return($mean);
}

sub getUserName {
  my $name = shift;
  my %users = (
    'aaron' => 'Aaron Wang (王士誠)',
    'jsyf' => '江謝逸帆',
    'ken' => '許勝達 Ken',
    'phuongddoan' => 'Phuong Duy Doan (段惟芳)',
    'yangtui' => '鄭仰兌',
    'esther' => 'Esther Chen (陳盈儒)'
  );

  if (defined($users{$name})) {
    $name = $users{$name};
  }
  else {
    $name = '江謝逸帆';
  }

  return($name);
}

sub getQCStandard {
=h
  /mnt/NFS/EC2480U-P/jsyf_tmp/jsyf_self/itemCode2Yield.tsv
  #itemCode       itemName        dataType        column  amount  unit
  NIMS-V3-300P-1G-SO      MiSeq v3 300PE 1G       raw     TotalBases      1       G
=cut
  my %pidPath = %{shift()};

  my %standard;
  if (-e '/mnt/NFS/EC2480U-P/jsyf_tmp/jsyf_self/itemCode2Yield.tsv') {
    my %factoe = ('K' => 1000, 'M' => 1000000, 'G' => 1000000000, 'T' => 1000000000000);
    my %header = ('itemCode' => 0, 'itemName' => 1, 'dataType' => 2, 'column' => 3, 'amount' => 4, 'unit' => 5);
    open(IN,'</mnt/NFS/EC2480U-P/jsyf_tmp/jsyf_self/itemCode2Yield.tsv');
    while (<IN>) {
      chomp;
      if ($_ eq '') {
        next;
      }

      if (($. == 1) && ($_ =~ /^#/)) {
        $_ =~ s/^#+//;
        my @h = split("\t", $_);
        for (my $i=0;$i<@h;$i++) {
          $header{$h[$i]} = $i;
        }
        next;
      }

      
    }
  }
}

# show results

sub showSimple {
#print 'List in showSimple: '.join(', ', @_)."\n";
  my $query = shift;
  my %pidPath = %{shift()};
  my $detail = 0;
  if (@_ > 0) {
    $detail = shift;
  }

  foreach my $pid (sort{$a cmp $b} (keys %pidPath)) {
    my @types = &fastqType($pid, $pidPath{$pid});

    my $concat = '';
    if ($pidPath{$pid} =~ /concat\/$/) {
      $concat = ' - '.chr(27).'[1;31mconcatenated'.chr(27).'[m';
    }

    foreach my $type (@types) {
      my %result = &getSampleStats($pid, $pidPath{$pid}, $type);
      # SampleName -> ['ReadPairs', 'TotalBases', 'R1', 'R2', 'R3']

      my $showType = $type;
      if (($type eq 'raw') || ($type eq 'clean')) {
        $showType = ucfirst($type).' Data'.$concat;
      }
      &showResult($pid, $showType, \%result, $detail);
    }
  }
}

sub showMerge {
  my $query = shift;
  my %pidPath = %{shift()};

  my %typeResult;
  foreach my $pid (sort{$a cmp $b} (keys %pidPath)) {
    foreach my $type (&fastqType($pid, $pidPath{$pid})) {
      my %thisResult = &getSampleStats($pid, $pidPath{$pid}, $type);
      push(@{$typeResult{$type}}, \%thisResult);
    }
  }

  foreach my $type ('raw', 'clean') {
    if (!defined($typeResult{$type})) {
      next;
    }

    my %results = &combineResult(@{$typeResult{$type}});

    my $showType = $type;
    if (($type eq 'raw') || ($type eq 'clean')) {
      $showType = ucfirst($type).' Data';
    }
    &showResult($query.' - Merge', $showType, \%results);
  }
}

# show order informations
sub showOrder {
  my $query = shift;
  my %pidPath = %{shift()};
  my $showProject = shift;

  my %pidOrder = &getOrder($query, \%pidPath);
  if (index($query, 'OL') == 0) {
    %pidOrder = &getOrderOlink($query, \%pidPath);
  }

  #my %qc = &getQCStandard(\%pidPath);

  foreach my $pid (sort{$a cmp $b} (keys %pidPath)) {
    if (!defined($pidOrder{$pid})) {
      next;
    }

    my $concat = ($pidPath{$pid} =~ /concat\/$/)?' - '.chr(27).'[1;31mconcatenated'.chr(27).'[m':'';

    #sales sales_email department customer sample_project idnum 
    #link_url link_password

    print '業務：'.$pidOrder{$pid}{'sales'}.' ( '.$pidOrder{$pid}{'sales_email'}.' )'."\n";
    print '單位：'.$pidOrder{$pid}{'department'}."\n";
    print '客戶：'.$pidOrder{$pid}{'customer'}."\n";
    if ($pidOrder{$pid}{'sample_project'} ne 'NA') {
      print '自製編號：'.$pidOrder{$pid}{'sample_project'}.$concat."\n";
    }
    print '內部編號：'.$pidOrder{$pid}{'idnum'}.$concat."\n";
    print '訂單品項：'."\n";
    my @items = @{$pidOrder{$pid}{'order_items'}};
    foreach my $item (@items) {
      my ($code, $name) = @{$item};
      printf("\t%-25s %s\n", $code, $name);
    }
    print '-'."\n";

    my @types = &fastqType($pid, $pidPath{$pid});
    foreach my $seqType (@types) {
      my %result = &getSampleStats($pid, $pidPath{$pid}, $seqType);
      &showResult($pid, ucfirst($seqType).' Data'.$concat, \%result);
    }
  }

  if ((grep {$_ !~ /-Analysis/} (keys %pidOrder)) > 1) {
    if ((grep {$pidPath{$_} =~ /concat\/$/} (keys %pidOrder)) == 0) {
      &showMerge($query, \%pidPath);
    }
  }

  my $workDays = 1;
  foreach my $pid (grep {$_ =~ /-Analysis$/} (keys %pidOrder)) {
    if (defined($pidOrder{$pid}{'work_days'}) && ($pidOrder{$pid}{'work_days'} > $workDays)) {
      $workDays = $pidOrder{$pid}{'work_days'};
    }
  }

  if (!defined($pidOrder{$showProject})) {
    $showProject = ${[sort{$a cmp $b} (keys %pidOrder)]}[0];
  }
  print "Project: ".$showProject."\n";

  print 'Mailto: '.$pidOrder{$showProject}{'sales_email'}.", ngs\@12953452.onmicrosoft.com\n".
        'Title: ['.((!defined($pidOrder{$showProject.'-Analysis'}) && ($ENV{'USER'} eq 'jsyf'))?'定序':'分析').'完成] '.$pidOrder{$showProject}{'department'}.(($pidOrder{$showProject}{'customer'} ne 'NA')?' '.$pidOrder{$showProject}{'customer'}:'').' ('.(($pidOrder{$showProject}{'sample_project'} ne 'NA')?$pidOrder{$showProject}{'sample_project'}.'，':'').'內部編號：'.$pidOrder{$showProject}{'idnum'}.') 已完成'."\n\n".
        'Hi,'."\n\n".
        '此件工時：'.$workDays.' days'."\n\n".
        '單位：'.$pidOrder{$showProject}{'department'}."\n".
        (($pidOrder{$showProject}{'customer'} ne 'NA')?'客戶：'.$pidOrder{$showProject}{'customer'}."\n":'').
        (($pidOrder{$showProject}{'sample_project'} ne 'NA')?'自製編號：'.$pidOrder{$showProject}{'sample_project'}."\n":'').
        '內部編號：'.$pidOrder{$showProject}{'idnum'}."\n".
        ''."\n".
        ((defined($pidOrder{$showProject.'-Analysis'}))?'下載連結：'.$pidOrder{$showProject.'-Analysis'}{'link_url'}."\n".'連結密碼：'.$pidOrder{$showProject.'-Analysis'}{'link_password'}."\n\n":'下載連結：'.$pidOrder{$showProject}{'link_url'}."\n".'連結密碼：'.$pidOrder{$showProject}{'link_password'}."\n\n").
#        '下載連結：'.$pidOrder{$showProject}{'link_url'}."\n".
#        '連結密碼：'.$pidOrder{$showProject}{'link_password'}."\n\n".
        '各樣本的 reads 數如下：'."\n\n\n".
        (((grep {$_ !~ /-Analysis/} (keys %pidOrder)) > 1)?'與先前結果合併後資料量如下：'."\n\n\n":'').
        '如果有問題麻煩跟我說。'."\n".
        '--'."\n".
        &getUserName($ENV{'USER'})."\n\n";
  print '=='."\n";
  if ((keys %pidOrder) > 1) {
    foreach my $pid (sort{$a cmp $b} (keys %pidOrder)) {
      print $pid.' 下載連結：'.$pidOrder{$pid}{'link_url'}."\n";
      print $pid.' 連結密碼：'.$pidOrder{$pid}{'link_password'}."\n";
    }
    print '=='."\n";
  }
}

# order informations
sub getOrder {
  my $query = shift;
  my %pidPath = %{shift()};

  my %pidOrder;
  foreach my $pid (sort{$a cmp $b} (keys %pidPath)) {
    my @logFiles;
    if ($pidPath{$pid} =~ /concat/) {
      my $runPath = $pidPath{$pid};
      $runPath =~ s/concat\/?.*$/runs\//;
      opendir(my $runs, $runPath);
      while (readdir($runs)) {
        if ($_ =~ /^\.+$/) { next; }

        if (-e $runPath.$_.'/logs/nextflow.log') {
          push(@logFiles, $runPath.$_.'/logs/nextflow.log');
        }
      }
      closedir($runs);

      undef($runPath);
      undef($runs);
    }
    else {
      if (-e $pidPath{$pid}.'logs/nextflow.log') {
        @logFiles = ($pidPath{$pid}.'logs/nextflow.log');
      }
      elsif (-e $pidPath{$pid}.'demux_logs/nextflow.log') {
        @logFiles = ($pidPath{$pid}.'demux_logs/nextflow.log');
      }
    }

    foreach my $logFile (@logFiles) {
      chomp(my $cmd = `head -n 1 ${logFile}`);
      if ($cmd =~ /\$>\s*/) { $cmd = $'; }
      my @info = split(/ +/, $cmd);

      my $cmdProgram = shift(@info);
      my @cmdList;
      my %cmdHash;

      my $i = 0;
      while ($i < @info) {
        if (($info[$i] !~ /^\-/) || ($info[$i+1] =~ /^\-/)) {
          push(@cmdList, $info[$i]);
        }
        else {
          my $key = $info[$i];
          $i ++;

          my $val = $info[$i];
          if (($val =~ /^[\'\"]/) && ($val !~ /[\'\"]$/)) {
            while ($val !~ /[\'\"]$/) {
              $i ++;
              $val .= ' '.$info[$i];
            }
          }
          $val =~ s/^[\'\"]//;
          $val =~ s/[\'\"]$//;

          $cmdHash{$key} = $val;
        }

        $i ++;
      }

      foreach my $col (qw / sales sales_email department customer sample_project idnum /) {
        if (!defined($cmdHash{'--'.$col})) {
          next;
        }
        if (!defined($pidOrder{$pid}{$col})) {
          $pidOrder{$pid}{$col} = $cmdHash{'--'.$col};
        }
        else {
          my %uniq;
          foreach my $uu (@{[split(';', $pidOrder{$pid}{$col})]}, $cmdHash{'--'.$col}) {
            $uniq{$uu} = 1;
          }

          $pidOrder{$pid}{$col} = join(';', (sort{$a cmp $b} (keys %uniq)));

          undef(%uniq);
          undef($uu)
        }
      }
      foreach my $item (@{[split(';', $cmdHash{'--order_items'})]}) {
        my ($code, $name) = split(/\s*:\s*/, $item);
        push(@{$pidOrder{$pid}{'order_items'}}, [$code, $name]);
      }

      undef(@cmdList);
      undef(%cmdHash);
    }

    undef(@logFiles);
    undef($logfile);

    if (-e $pidPath{$pid}.'link.txt') {
      open(IN,'<'.$pidPath{$pid}.'link.txt');
      while (<IN>) {
        chomp;
        if ($_ eq '') {
          next;
        }

        if ($. == 2) {
          $pidOrder{$pid}{'link_url'} = $_;
        }
        elsif ($. == 3) {
          $pidOrder{$pid}{'link_password'} = $_;
        }
      }
      close(IN);
    }

    my $analysisFolder = $pidPath{$pid};
    $analysisFolder =~ s/FASTQ\/*.*$/Analysis\//;
    if (-e $analysisFolder) {
      if (-e $analysisFolder.'link.txt') {
        open(IN,'<'.$analysisFolder.'link.txt');
        while (<IN>) {
          chomp;
          if ($_ eq '') {
            next;
          }

          if ($. == 2) {
            $pidOrder{$pid.'-Analysis'}{'link_url'} = $_;
          }
          elsif ($. == 3) {
            $pidOrder{$pid.'-Analysis'}{'link_password'} = $_;
          }
        }
        close(IN);
      }

      if ($ENV{'USER'} eq 'jsyf') {
        my $workingDir = '';
        opendir(my $fh, $analysisFolder);
        while (readdir($fh)) {
          if (($_ !~ /^\./) && (-l $analysisFolder.$_) && (-d readlink($analysisFolder.$_))) {
            $workingDir = readlink($analysisFolder.$_);
          }
        }
        closedir($fh);

        my $workDays = 1;
        opendir(my $fh, $workingDir);
        while (readdir($fh)) {
          if (($_ =~ /^\./) || (-l $workingDir.$_)) { next; }
          my $dd = -M $workingDir.$_;
          if ($dd > $workDays) {
            $workDays = $dd;
          }
        }
        closedir($fh);

        if ($workDays > int($workDays)) {
          $workDays = int($workDays) + 1;
        }

        $pidOrder{$pid.'-Analysis'}{'work_days'} = $workDays;
      }
    }
  }

  return(%pidOrder);
}

# order informations for Olink projects
sub getOrderOlink {
  my $query = shift;
  my %pidPath = %{shift()};

  my %pidOrder;
  foreach my $pid (sort{$a cmp $b} (keys %pidPath)) {
    my @logFiles;
    if (-e $pidPath{$pid}.'info.txt') {
      push(@logFiles, $pidPath{$pid}.'info.txt');
    }
    else {
      my $infoFile = $pidPath{$pid}.'info.txt';
      $infoFile =~ s/\/Data\//\//;

      if (-e $infoFile) {
        push(@logFiles, $infoFile);
      }
    }

    foreach my $logFile (@logFiles) {
      open(IN,'<'.$logFile);
      while (<IN>) {
        chomp;
        if ($_ eq '') {
          next;
        }

        my ($name, $val) = split(': ', $_);

        if (($name eq '') || ($val eq '')) {next;}

        if ($name eq 'Project') {
          $pidOrder{$pid}{'sample_project'} = $val;
        }
        elsif ($name eq 'Custom') {
          $pidOrder{$pid}{'department'} = $val;
          $pidOrder{$pid}{'customer'} = $val;
        }
        elsif ($name eq 'Item') {
          push(@{$pidOrder{$pid}{'order_items'}}, ['NA', $val]);
        }
      }
      close(IN);
    }

    undef(@logFiles);
    undef($logfile);

    my $linkFile = $pidPath{$pid}.'link.txt';
    if (!-e $linkFile) {
      $linkFile =~ s/\/Data\//\/Analysis\//;
      if (!-e $linkFile) {
        $linkFile =~ s/\/Analysis\//\//;
      }
    }

    if (-e $linkFile) {
      open(IN,'tail -n 3 '.$linkFile.' | ');
      while (<IN>) {
        chomp;
        if ($_ eq '') {
          next;
        }

        if ($. == 2) {
          $pidOrder{$pid.(($linkFile =~ /Analysis/ )?'-Analysis':'')}{'link_url'} = $_;
        }
        elsif ($. == 3) {
          $pidOrder{$pid.(($linkFile =~ /Analysis/ )?'-Analysis':'')}{'link_password'} = $_;
        }
      }
      close(IN);
    }

    my $analysisFolder = $pidPath{$pid};
    $analysisFolder =~ s/Data\/*.*$/Analysis\//;
    if (-e $analysisFolder) {
      if ($ENV{'USER'} eq 'jsyf') {
        my $workingDir = '';
        opendir(my $fh, $analysisFolder);
        while (readdir($fh)) {
          if (($_ !~ /^\./) && (-l $analysisFolder.$_) && (-d readlink($analysisFolder.$_))) {
            $workingDir = readlink($analysisFolder.$_);
          }
        }
        closedir($fh);

        my $workDays = 1;
        opendir(my $fh, $workingDir);
        while (readdir($fh)) {
          if (($_ =~ /^\./) || (-l $workingDir.$_)) { next; }
          my $dd = -M $workingDir.$_;
          if ($dd > $workDays) {
            $workDays = $dd;
          }
        }
        closedir($fh);

        if ($workDays > int($workDays)) {
          $workDays = int($workDays) + 1;
        }

        $pidOrder{$pid.'-Analysis'}{'work_days'} = $workDays;
      }
    }
  }

  return(%pidOrder);
}

sub main {
  my $query = shift;
  my $job = '';

  if ($query =~ /:/) {
    ($job, $query) = split(':', $query);
  }

  $job = ucfirst(lc($job));
  if (($job ne 'Simple') && ($job ne 'Merge') && ($job ne 'Detail')) {
    $job = 'Order';
  }

  #if (index($query, 'OL') == 0) {
  #  
  #}

  if ($job eq 'Order') {
    my $root = $query;
    ($root) = split('-', $root);

    my %pidPath = &findRelatedProjectPath($root);
    &showOrder($root, \%pidPath, $query);
  }
  else {
    my %pidPath = &findRelatedProjectPath($query);
    if (((keys %pidPath) == 1) && ($job ne 'Detail')) {
      $job = 'Simple';
    }

    if ($job eq 'Simple') {
#print 'Query in Simple: '.$query."\n";
      &showSimple($query, \%pidPath);
    }
    elsif ($job eq 'Merge') {
      &showMerge($query, \%pidPath);
    }
    elsif ($job eq 'Detail') {
#print 'Query in Detail: '.$query."\n";
      &showSimple($query, \%pidPath, 1);
    }
  }
}

#my $q = shift;
#&main($q);

foreach my $q (@ARGV) {
  &main($q);
}




