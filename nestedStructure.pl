while (<>) {
  chomp;

  $_ =~ s/^\(/ \(/;
  $_ =~ s/\)$/\) /;

  $_ =~ s/(?<= )(\|\||\&\&|\(|\))(?= )/\t${1}\t/g;
  $_ =~ s/\s*\t\s*/\t/g;

  my @array = split(/\t/, $_);

  my $indent = 0;
  for (my $i=0;$i<@array;$i++) {
    if ($array[$i] eq ")") {
      $indent --;
    }

    print "   "x$indent;
    print $indent.": ".$array[$i]."\n";

    if ($array[$i] eq "(") {
      $indent ++
    }
  }
}
