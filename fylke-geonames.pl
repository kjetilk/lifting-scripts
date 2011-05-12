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
		     rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
		    },
      base_uri => 'http://data.lenka.no/geo/inndeling/',
      ExpandQNames => 1,
   );

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

foreach my $row (@{$res->{rows}}) {
  next unless ($row->{fnr});
  if (length($row->{fnr}) == 1) {
    $row->{fnr} = "0$row->{fnr}";
  }

  $row->{lat} =~ s/\s//g;
  $row->{long} =~ s/\s//g;

  my $fylke = $rdf->get_object($row->{fnr});
  $fylke->rdf_type('http://vocab.lenka.no/geo-deling#Fylke');
  $fylke->gd_fylkenr($row->{fnr});
  $rdf->assert_literal($row->{fnr}, 'gn:officialName', $rdf->new_literal($row->{no},  'no'));
  $rdf->assert_literal($row->{fnr}, 'gn:officialName', $rdf->new_literal($row->{se},  'se'));
  $rdf->assert_literal($row->{fnr}, 'gn:officialName', $rdf->new_literal($row->{fkv},  'fkv'));
  $fylke->pos_lat($row->{lat});
  $fylke->pos_long($row->{long});
  $fylke->owl_sameAs("http://sws.geonames.org/$row->{geonames}/");
}

my $dump = $rdf->get_object('/dumps/fylke-geonames.ttl');

$dump->rdf_type('http://creativecommons.org/ns#Work');
$dump->cc_license('http://creativecommons.org/licenses/by/3.0/');
$dump->cc_attributionName('Erik Bolstad');
$dump->cc_attributionURL('http://www.erikbolstad.no/geo/noreg/fylke/');

print $rdf->serialize(format => 'turtle')
