#!/usr/bin/perl
use strict;
use utf8;
use warnings;
binmode(STDOUT, ":utf8");

use URI;
use Web::Scraper;

my $rows = scraper {
  process "tr", "rows[]" => scraper {
    process "td" , fnr => 'TEXT';
    process "td + td" , no => 'TEXT';
    process "td + td + td" , se => 'TEXT';
    process "td + td + td + td" , fkv => 'TEXT';
    process "td + td + td + td + td" , geonames => 'TEXT';
    process "td + td + td + td + td + td" , ssr => 'TEXT';
    process "td + td + td + td + td + td + td" , lat => 'TEXT';
    process "td + td + td + td + td + td + td + td" , long => 'TEXT';
  };
};

my $res = $rows->scrape( URI->new("http://www.erikbolstad.no/geo/noreg/fylke/txt/") );

print '@base <http://lod.kjernsmo.net/matrikkel/> .' . "\n";
print '@prefix gn: <http://www.geonames.org/ontology#> .' . "\n";
print '@prefix owl: <http://www.w3.org/2002/07/owl#> .'. "\n";
print '@prefix pos: <http://www.w3.org/2003/01/geo/wgs84_pos#> .' . "\n";
print '@prefix gd: <http://vocab.lenka.no/geo-deling#> .' . "\n";
print '@prefix cc: <http://creativecommons.org/ns#> .' . "\n";

foreach my $row (@{$res->{rows}}) {
  next unless ($row->{fnr});
  if (length($row->{fnr}) == 1) {
    $row->{fnr} = "0$row->{fnr}";
  }

  $row->{lat} =~ s/\s//g;
  $row->{long} =~ s/\s//g;

  print "\n<$row->{fnr}> a ng:Fylke ;\n";
  print "\tng:fylkenr \"$row->{fnr}\" ;\n";
  print "\tgn:officialName \"$row->{no}\"\@no ;\n";
  print "\tgn:officialName \"$row->{se}\"\@se ;\n";
  print "\tgn:officialName \"$row->{fkv}\"\@fkv ;\n";
  print "\tpos:lat \"$row->{lat}\" ; \n";
  print "\tpos:long \"$row->{long}\" ; \n";
  print "\towl:sameAs <http://sws.geonames.org/$row->{geonames}/> .\n";
}

print "\n</dumps/fylke-geonames.ttl> a cc:Work ;\n";
print "\tcc:license <http://creativecommons.org/licenses/by/3.0/> ;\n";
print "\tcc:attributionName \"Erik Bolstad\" ;\n";
print "\tcc:attributionURL <http://www.erikbolstad.no/geo/noreg/fylke/> .\n";
