#!perl -T
use Test::More tests => 15;

BEGIN {
 	use_ok( 'WWW::Wikipedia::TemplateFiller' );
}

use HTML::Entities;

my $ndash = decode_entities('&ndash;');
my $filler = new WWW::Wikipedia::TemplateFiller();
my( $source, $temp );

$source = $filler->get( pubmed_id => '15841477' );

is( $source->fill->output( link_journal => 1, add_accessdate => 0 ), "{{cite journal |author=Xu L, Liu SL, Zhang JT |title=(-)-Clausenamide potentiates synaptic transmission in the dentate gyrus of rats |journal=[[Chirality]] |volume=17 |issue=5 |pages=239${ndash}44 |year=2005 |pmid=15841477 |doi=10.1002/chir.20150 |url=}}", 'cite journal output' );

is( $source->{journal}, 'Chirality', 'journal' );
is( $source->{pmid}, '15841477', 'pmid' );

is( $source->fill->output( add_accessdate => 0, add_text_url => 1 ), "{{cite journal |author=Xu L, Liu SL, Zhang JT |title=(-)-Clausenamide potentiates synaptic transmission in the dentate gyrus of rats |journal=Chirality |volume=17 |issue=5 |pages=239${ndash}44 |year=2005 |pmid=15841477 |doi=10.1002/chir.20150 |url=http://dx.doi.org/10.1002/chir.20150}}", 'cite journal output' );

is( $source->fill->output( vertical => 1, add_accessdate => 0 ), "{{cite journal
|author=Xu L, Liu SL, Zhang JT
|title=(-)-Clausenamide potentiates synaptic transmission in the dentate gyrus of rats
|journal=Chirality
|volume=17
|issue=5
|pages=239${ndash}44
|year=2005
|pmid=15841477
|doi=10.1002/chir.20150
|url=
}}", 'cite journal vertical output' );

$source = $filler->get( url => 'http://en.wikipedia.org' );
is( $source->{title}, 'Main Page - Wikipedia, the free encyclopedia', 'title' );

is( $filler->get( url => 'http://en.wikipedia.org' )->fill->output( add_accessdate => 1 ), '{{cite web |url=http://en.wikipedia.org |title=Main Page - Wikipedia, the free encyclopedia |format= |work= |accessdate='.WWW::Wikipedia::TemplateFiller::Source->__today_and_now.'}}', 'cite web template' );

$source = $filler->get( pubchem_id => 12345 );
is( $source->{iupac_name}, 'acetic acid acetoxymethyl ester', 'IUPACName match' );

is( $filler->get( pubchem_id => 12345 )->fill->output( vertical => 1 ), '{{chembox new
|ImageFile=
|ImageSize=
|IUPACName=acetic acid acetoxymethyl ester
|OtherNames=
|Section1={{Chembox Identifiers
|  CASNo=
|  PubChem=12345
|  SMILES=CC(=O)OCOC(=O)C
  }}
|Section2={{Chembox Properties
|  Formula=C<sub>5</sub>H<sub>8</sub>O<sub>4</sub>
|  MolarMass=132.11462
|  Appearance=
|  Density=
|  MeltingPt=
|  BoilingPt=
|  Solubility=
  }}
|Section3={{Chembox Hazards
|  MainHazards=
|  FlashPt=
|  Autoignition=
  }}
}}', 'chembox template' );

$data = $filler->get( hgnc_id => 'HGNC:1582' );
is( $data->{approved_symbol}, 'CCND1', 'Symbol match' );

is( $filler->get( hgnc_id => 'HGNC:1582' )->fill( template => 'protein' )->output, '{{protein |name=cyclin D1 |caption= |image= |width= |HGNCid=1582 |Symbol=CCND1 |AltSymbols=BCL1, D11S287E, PRAD1 |EntrezGene= |OMIM= |RefSeq= |UniProt= |PDB= |ECnumber= |Chromosome=11 |Arm=q |Band=13 |LocusSupplementaryData=}}', 'protein template' );

is( $filler->get( drugbank_id => 'DB00338' )->fill( template => 'drugbox' )->output, '{{drugbox |IUPAC_name=6-methoxy-2-[(4-methoxy-3,5-dimethylpyridin-2-yl)methylsulfinyl]-1H-benzimidazole |image={{PAGENAME}}.png |CAS_number=73590-58-6 |ATC_prefix= |ATC_suffix= |ATC_supplemental= |PubChem= |DrugBank=DB00338 |chemical_formula=C<sub>17</sub>H<sub>19</sub>N<sub>3</sub>O<sub>3</sub>S |molecular_weight= |bioavailability= |protein_bound=95% |metabolism= |elimination_half-life=0.5-1 hour |excretion= |pregnancy_AU=<!-- A / B1 / B2 / B3 / C / D / X --> |pregnancy_US=<!-- A / B / C / D / X --> |pregnancy_category= |legal_AU=<!-- Unscheduled / S2 / S4 / S8 --> |legal_UK=<!-- GSL / P / POM / CD --> |legal_US=<!-- OTC / Rx-only --> |legal_status= |routes_of_administration=}}' );

$data = $filler->get( drugbank_id => 'DB00700' );
is( $data->{cas_registry_number}, '107724-20-9', 'CAS_number match' );

my $access_key = $ENV{ISBNDB_ACCESS_KEY};

{
  no warnings;
  use WWW::Scraper::ISBN::ISBNdb_Driver;
  $WWW::Scraper::ISBN::ISBNdb_Driver::ACCESS_KEY = $access_key;
}

SKIP: {
  skip "no isbndb.com access key provided in the ISBNDB_ACCESS_KEY environment variable" => 1 unless $access_key;
  $data = $filler->get( isbn => '0805372989' );
  is( $data->{location}, 'San Francisco', 'isbn location match' );
}
