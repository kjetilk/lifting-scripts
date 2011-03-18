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
    process "td + td" , kgeonames => 'TEXT';
    process "td + td + td" , no => 'TEXT';
    process "td + td + td + td" , fnr => 'TEXT';
    process "td + td + td + td + td" , f => 'TEXT';
    process "td + td + td + td + td + td" , pop => 'TEXT';
    process "td + td + td + td + td + td + td" , klat => 'TEXT';
    process "td + td + td + td + td + td + td + td" , klong => 'TEXT';
    process "td + td + td + td + td + td + td + td + td" , admno => 'TEXT';   
    process "td + td + td + td + td + td + td + td + td + td" , ssr => 'TEXT';   
    process "td + td + td + td + td + td + td + td + td + td + td" , geonames => 'TEXT';   
    process "td + td + td + td + td + td + td + td + td + td + td + td" , lat => 'TEXT';
    process "td + td + td + td + td + td + td + td + td + td + td + td + td" , long => 'TEXT';
  };
};

my $res = $rows->scrape( URI->new("http://www.erikbolstad.no/geo/skandinavia/norske-kommunesenter/txt/") );

print '@base <http://lod.kjernsmo.net/> .' . "\n";

print '@prefix gn: <http://www.geonames.org/ontology#> .' . "\n";
print '@prefix owl: <http://www.w3.org/2002/07/owl#> .'. "\n";
print '@prefix pos: <http://www.w3.org/2003/01/geo/wgs84_pos#> .' . "\n";
print '@prefix gd: <http://vocab.lenka.no/geo-deling#> .' . "\n";
print '@prefix cc: <http://creativecommons.org/ns#> .' . "\n";

foreach my $row (@{$res->{rows}}) {
  next unless ($row->{admno} && $row->{ssr} );
  if (length($row->{fnr}) == 1) {
    $row->{fnr} = "0$row->{fnr}";
  }
  if (length($row->{knr}) == 3) {
    $row->{knr} = "0$row->{knr}";
  }

  $row->{lat} =~ s/\s//g;
  $row->{long} =~ s/\s//g;

  print "\n<matrikkel/$row->{fnr}/$row->{knr}> a ng:Kommune ;\n";
  if ($row->{kgeonames}) {
    print "\towl:sameAs <http://sws.geonames.org/$row->{kgeonames}/> ;\n";
  }
  print "\tgn:parentFeature <matrikkel/$row->{fnr}> ;\n";
  print "\tng:fylkenr \"$row->{fnr}\" ;\n";
  print "\tng:kommunenr \"$row->{knr}\" ;\n";
  print "\tpos:lat \"$row->{klat}\" ; \n";
  print "\tpos:long \"$row->{klong}\" . \n";
  print "\n<matrikkel/$row->{fnr}> gn:childrenFeatures <matrikkel/$row->{fnr}/$row->{knr}> .\n";

  print "\n<sted/$row->{ssr}> a ng:Kommunesenter ;\n";
  print "\tgn:parentFeature <matrikkel/$row->{fnr}/$row->{knr}> ;\n";
  print "\tgn:parentADM1 <matrikkel/$row->{fnr}> ;\n";
  print "\tgn:parentADM2 <matrikkel/$row->{fnr}/$row->{knr}> ;\n";
  if ($row->{geonames}) {
    print "\towl:sameAs <http://sws.geonames.org/$row->{geonames}/> ;\n";
  }
  print "\tpos:lat \"$row->{lat}\" ; \n";
  print "\tpos:long \"$row->{long}\" ; \n";
  print "\tgn:officialName \"$row->{admno}\"\@no .\n";

}

print "\n</dumps/kommunesentre-geonames.ttl> a cc:Work ;\n";
print "\tcc:license <http://creativecommons.org/licenses/by/3.0/> ;\n";
print "\tcc:attributionName \"Erik Bolstad\" ;\n";
print "\tcc:attributionURL <http://www.erikbolstad.no/geo/skandinavia/norske-kommunesenter/> .\n";
