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
		     gd => 'http://vocab.lenka.no/geo-deling#',
		     cc => 'http://creativecommons.org/ns#',
		     rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
		    },
      base_uri => 'http://data.lenka.no/geo/inndeling/',
      ExpandQNames => 1,
   );

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

foreach my $row (@{$res->{rows}}) {
  next unless ($row->{knr});
  if (length($row->{fnr}) == 1) {
    $row->{fnr} = "0$row->{fnr}";
  }
  if (length($row->{knr}) == 3) {
    $row->{knr} = "0$row->{knr}";
  }

  my $subject = "$row->{fnr}/$row->{knr}";
  $rdf->assert_resource($subject, 'rdf:type', 'gd:Kommune');
  $rdf->assert_literal($subject, 'gn:officialName', $rdf->new_literal($row->{no},  'no'));
  $rdf->assert_literal($subject, 'gn:officialName', $rdf->new_literal($row->{fkv},  'fkv'));
  if ($row->{se}) {
    $rdf->assert_literal($subject, 'gn:officialName', $rdf->new_literal($row->{se},  'se'));
  }
}

my $dump = $rdf->get_object('/dumps/kommune-navn.ttl');

$dump->rdf_type('http://creativecommons.org/ns#Work');
$dump->cc_license('http://creativecommons.org/licenses/by/3.0/');
$dump->cc_attributionName('Erik Bolstad');
$dump->cc_attributionURL('http://www.erikbolstad.no/geo/noreg/kommunar/');

print $rdf->serialize(format => 'turtle')
