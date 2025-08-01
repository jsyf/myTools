my @table;
my @header;
my @colWidth;

while (<>) {
  chomp;

  my @array = split("\t", $_);

  if ($. == 1) {
    @header = @array;
  }
  else {
    push(@table, \@array);
  }

  for (my $i=0;$i<@array;$i++) {
    if ($colWidth[$i] < length($array[$i])) {
      $colWidth[$i] = length($array[$i]);
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

printf($pattern, @header);
print $split;

foreach my $row (@table) {
  printf($pattern, @{$row});
}
