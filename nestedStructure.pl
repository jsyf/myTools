my $showLvl = 0;

while (<>) {
  chomp;

  $_ =~ s/^\(/ \(/;
  $_ =~ s/\)$/\) /;

  $_ =~ s/(?<= )(\|\||\&\&|\(|\))(?= )/\t${1}\t/g;
  $_ =~ s/\s*\t\s*/\t/g;

  my @array = split(/\t/, $_);

  my $indent = 0;
  for (my $i=0;$i<@array;$i++) {
    $array[$i] =~ s/^ +//;
    $array[$i] =~ s/ +$//;

    if ($array[$i] eq ")") {
      $indent --;
    }

    print( ( ("  ".(" "x$showLvl)) x $indent ) . chr(27)."[1;37m" . (($showLvl == 1)?$indent.": ":'') . $array[$i].chr(27)."[m\n");

    if ($array[$i] eq "(") {
      $indent ++;
    }
  }
}
