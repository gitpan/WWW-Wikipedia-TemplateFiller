package WWW::Wikipedia::TemplateFiller::Source::PubmedcentralId;
use base 'WWW::Wikipedia::TemplateFiller::Source::PubmedId';

use WWW::Mechanize;
use XML::LibXML;

sub get {
  my( $self, $pmcid ) = @_;
  my $www = new WWW::Mechanize();
  $www->get(sprintf 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=pmc&id=%s&db=pubmed', $pmcid );
  my $xml = $www->content;
  my $parser = new XML::LibXML();
  my $doc = $parser->parse_string($xml);
  my $pmid = $doc->findvalue('/eLinkResult/LinkSet/LinkSetDb[LinkName="pmc_pubmed"]/Link/Id');
  return $self->SUPER::get($pmid);
}

1;
