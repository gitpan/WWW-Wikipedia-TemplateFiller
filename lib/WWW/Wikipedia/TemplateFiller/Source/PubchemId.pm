package WWW::Wikipedia::TemplateFiller::Source::PubchemId;
use base 'WWW::Wikipedia::TemplateFiller::Source';

use warnings;
use strict;

use Tie::IxHash;

sub search_class { 'PubChem' }

sub get {
  my( $self, $pubchem_id ) = @_;
  my $chem = $self->_search($pubchem_id);

  return $self->__source_obj( {
    __source_url => $chem->url,
    pubchem_id => $pubchem_id,
    %$chem
  } );
}

sub output {
  my( $self, %args ) = @_;
  $args{vertical} = 1;
  return $self->SUPER::output(%args);
}

sub template_name { 'chembox new' }
sub template_ref_name { 'chem'.shift->{pubchem_id} }
sub template_basic_fields {
  my $self = shift;

  ( my $formula_html = $self->{molecular_formula} ) =~ s{(\d+)}{<sub>$1</sub>}g;

  tie( my %fields, 'Tie::IxHash' );
  %fields = (
    -ImageFile => '',
    -ImageSize => '',
    -IUPACName => $self->{iupac_name},
    -OtherNames => '',
    -Section1 => sprintf( "{{Chembox Identifiers\n|  %s=%s\n|  %s=%s\n|  %s=%s\n  }}",
      CASNo => '',
      PubChem => $self->{pubchem_id},
      SMILES => $self->{smiles},
    ),
    -Section2 => sprintf( "{{Chembox Properties\n|  %s=%s\n|  %s=%s\n|  %s=%s\n|  %s=%s\n|  %s=%s\n|  %s=%s\n|  %s=%s\n  }}",
      Formula => $formula_html,
      MolarMass => $self->{molecular_weight},
      Appearance => '',
      Density => '',
      MeltingPt => '',
      BoilingPt => '',
      Solubility => '',
    ),
    -Section3 => sprintf( "{{Chembox Hazards\n|  %s=%s\n|  %s=%s\n|  %s=%s\n  }}",
      MainHazards => '',
      FlashPt => '',
      Autoignition => '',
    ),
  );

  return \%fields;
}

1;
