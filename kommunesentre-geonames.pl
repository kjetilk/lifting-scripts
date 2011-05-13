#!/usr/bin/perl
use strict;
use utf8;
use warnings;
binmode(STDOUT, ":utf8");

use URI;
use Web::Scraper;
use RDF::Helper '1.99_02';
my $rdf = RDF::Helper->new(
      namespaces => {
		     gn => 'http://www.geonames.org/ontology#',
		     owl => 'http://www.w3.org/2002/07/owl#',
		     pos => 'http://www.w3.org/2003/01/geo/wgs84_pos#',
		     gd => 'http://vocab.lenka.no/geo-deling#',
		     cc => 'http://creativecommons.org/ns#',
		     xsd => 'http://www.w3.org/2001/XMLSchema#',
		     rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
		    },
      base_uri => 'http://data.lenka.no/geo/',
      ExpandQNames => 1,
   );

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

  my $kommune = "inndeling/$row->{fnr}/$row->{knr}";
  $rdf->assert_resource($kommune, 'rdf:type', 'gd:Kommune');
  if ($row->{kgeonames}) {
    $rdf->assert_resource($kommune, 'owl:sameAs' , "http://sws.geonames.org/$row->{kgeonames}/");
  }
  $rdf->assert_resource($kommune, 'gn:parentFeature', "inndeling/$row->{fnr}");
  $rdf->assert_literal($kommune, 'gd:fylkenr', $row->{fnr});
  $rdf->assert_literal($kommune, 'gd:kommunenr', $row->{knr});
  $rdf->assert_resource($kommune, 'gd:senter', "sted/$row->{ssr}");
  $rdf->assert_literal($kommune, 'pos:lat', $rdf->new_literal($row->{klat}, undef, 'xsd:decimal'));
  $rdf->assert_literal($kommune, 'pos:long', $rdf->new_literal($row->{klong}, undef, 'xsd:decimal'));

  $rdf->assert_resource("inndeling/$row->{fnr}", 'gn:childrenFeatures', "inndeling/$row->{fnr}/$row->{knr}");

  my $sted = "sted/$row->{ssr}";
  $rdf->assert_resource($sted, 'rdf:type', 'http://vocab.lenka.no/geo-deling#Kommunesenter');
  $rdf->assert_resource($sted, 'gn:parentFeature', "inndeling/$row->{fnr}/$row->{knr}");
  $rdf->assert_resource($sted, 'gn:parentADM1', "inndeling/$row->{fnr}");
  $rdf->assert_resource($sted, 'gn:parentADM2', "inndeling/$row->{fnr}/$row->{knr}");
  if ($row->{geonames}) {
    $rdf->assert_resource($sted, 'owl:sameAs', "http://sws.geonames.org/$row->{geonames}/");
  }
  $rdf->assert_literal($sted, 'pos:lat', $rdf->new_literal($row->{lat}, undef, 'xsd:decimal'));
  $rdf->assert_literal($sted, 'pos:long', $rdf->new_literal($row->{long}, undef, 'xsd:decimal'));
  $rdf->assert_literal($sted, 'gn:officialName', $rdf->new_literal($row->{admno},  'no'));
}

my $dump = $rdf->get_object('/dumps/kommunesentre-geonames.ttl');

$dump->rdf_type('http://creativecommons.org/ns#Work');
$dump->cc_license('http://creativecommons.org/licenses/by/3.0/');
$dump->cc_attributionName('Erik Bolstad');
$dump->cc_attributionURL('http://www.erikbolstad.no/geo/skandinavia/norske-kommunesenter/');

print $rdf->serialize(format => 'turtle')
