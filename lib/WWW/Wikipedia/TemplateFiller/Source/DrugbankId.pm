package WWW::Wikipedia::TemplateFiller::Source::DrugbankId;
use base 'WWW::Wikipedia::TemplateFiller::Source';

use warnings;
use strict;

use Tie::IxHash;

sub search_class { 'DrugBank' }

sub get {
  my( $self, $drugbank_id ) = @_;
  my $drug = $self->_search($drugbank_id);
  return undef unless $drug;

  return $self->__source_obj( {
    __source_url => $drug->{_url},
    %$drug
  } );
}

sub template_name { 'drugbox' }
sub template_ref_name { 'drug'.shift->{accession_number} }
sub template_basic_fields {
  my $self = shift;

  my $cat = $self->{category};

  my @atc_codes = map {
    /^(...)(....)$/;
    { prefix => $1, suffix => $2 };
  } map {
    $_->{code};
  } grep {
    length $_->{code} == 7
  } @{ $cat && $cat->{atc} || [] };

  my $first_atc = shift @atc_codes;
  my $supplemental_atc = join ', ', map { sprintf '{{ATC|%s|%s}}', $_->{prefix}, $_->{suffix} } @atc_codes;

  ( my $chemical_formula_html = $self->{chemical_formula} )=~ s~(\d+)~<sub>$1</sub>~g;

  my $melting_point;
  if( $self->{melting_point} ) {
    $self->{melting_point} =~ /(\d+\.\d+)/;
    $melting_point = $1;
  }

  tie( my %fields, 'Tie::IxHash' );
  %fields = (
    -IUPAC_name => $self->{chemical_iupac_name},
    -image => '{{PAGENAME}}.png',
    image2 => undef,
    width => undef,
    -CAS_number => $self->{cas_registry_number},
    CAS_supplemental => undef,
    -ATC_prefix => $first_atc->{prefix},
    -ATC_suffix => $first_atc->{suffix},
    ATC_supplemental => $supplemental_atc,
    -PubChem => $self->{pubchem_id}->{compound},
    -DrugBank => $self->{accession_number},
    -chemical_formula => $chemical_formula_html,
    -molecular_weight => $self->{molecular_weight},
    '+smiles' => $self->{smiles_string},
    density => undef,
    '+melting_point' => $self->{melting_point},
    boiling_point => undef,
    solubility => $self->{h2o_solubility},
    specific_rotation => undef,
    sec_combustion => undef,
    -bioavailability => undef,
    -protein_bound => $self->{protein_binding},
    -metabolism => undef,
    '-elimination_half-life' => $self->{half_life},
    -excretion => undef,
    dependency_liability => undef,

    # New field from David Ruben
    -pregnancy_AU => '<!-- A / B1 / B2 / B3 / C / D / X -->',
    -pregnancy_US => '<!-- A / B / C / D / X -->',
    -pregnancy_category => undef,
    -legal_AU => '<!-- Unscheduled / S2 / S4 / S8 -->',
    -legal_UK => '<!-- GSL / P / POM / CD -->',
    -legal_US => '<!-- OTC / Rx-only -->',
    -legal_status => undef,

    -routes_of_administration => undef,
  );

  return \%fields;
}

1;
