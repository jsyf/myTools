#!/usr/bin/env perl
use strict;

use Vcf;
use JSON;

my $fusion = shift;

my $vcf = Vcf->new(file=>$fusion);
$vcf->parse_header();

foreach my $header_line (@{$vcf->{header_lines}}) {
    my @keyOrder;
    if (defined($header_line->{'key'})) {
      push(@keyOrder, 'key');
    }
    if (defined($header_line->{'ID'})) {
      push(@keyOrder, 'ID');
    }
    foreach my $k (sort{$a cmp $b} (keys %{$header_line})) {
      if (($k eq 'key') || ($k eq 'ID') || ($k eq 'Description')) {
        next;
      }
      push(@keyOrder, $k);
    }
    if (defined($header_line->{'Description'})) {
      push(@keyOrder, 'Description');
    }

    print 'Header: {';
    foreach my $k (@keyOrder) {
      if ($k ne $keyOrder[0]) {print ', ';}
      print '"'.$k.'": ';
      if (!ref($header_line->{$k})) {
        print '"'.$header_line->{$k}.'"';
      }
      else {
        print ref($header_line->{$k});
      }
    }
    print '}'.$/;
    #print "Header: {".join(', ', (map{'"'.$_.'": "'.$header_line->{$_}.'"'} (@keyOrder)))."}\n";
}
