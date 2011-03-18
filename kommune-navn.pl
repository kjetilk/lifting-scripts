#!/usr/bin/perl
use strict;
use utf8;
use warnings;
binmode(STDOUT, ":utf8");

use URI;
use Web::Scraper;

my $rows = scraper {
  process "tr", "rows[]" => scraper {
    process "td" , knr => 'TEXT';
    process "td + td" , geonames => 'TEXT';
    process "td + td + td" , no => 'TEXT';
    process "td + td + td + td" , se => 'TEXT';
    process "td + td + td + td + td" , fkv => 'TEXT';
    process "td + td + td + td + td + td" , fnr => 'TEXT';
  };
};

my $res = $rows->scrape( URI->new("http://www.erikbolstad.no/geo/noreg/kommunar/txt/") );

print '@base <http://data.lenka.no/geo/inndeling/> .' . "\n";
print '@prefix gn: <http://www.geonames.org/ontology#> .' . "\n";
print '@prefix cc: <http://creativecommons.org/ns#> .' . "\n";

foreach my $row (@{$res->{rows}}) {
  next unless ($row->{knr});
  if (length($row->{fnr}) == 1) {
    $row->{fnr} = "0$row->{fnr}";
  }
  if (length($row->{knr}) == 3) {
    $row->{knr} = "0$row->{knr}";
  }
  
  print "\n<$row->{fnr}/$row->{knr}>\n";
  print "\tgn:officialName \"$row->{no}\"\@no ;\n";
  if ($row->{se}) {
    print "\tgn:officialName \"$row->{se}\"\@se ;\n";
  }
  print "\tgn:officialName \"$row->{fkv}\"\@fkv .\n";
}


print "\n</dumps/kommune-navn.ttl> a cc:Work ;\n";
print "\tcc:license <http://creativecommons.org/licenses/by/3.0/> ;\n";
print "\tcc:attributionName \"Erik Bolstad\" ;\n";
print "\tcc:attributionURL <http://www.erikbolstad.no/geo/noreg/kommunar/> .\n";
