package WWW::Wikipedia::TemplateFiller::Source::PubchemId;
use base 'WWW::Wikipedia::TemplateFiller::Source';

use warnings;
use strict;

use Tie::IxHash;

# Terrible hack to enable more elegant solution to bug #41005
my $EscapedPipe = '98lkdfb832nbueh92x0jngfk';

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

  my $output = $self->SUPER::output(%args);
     $output =~ s/$EscapedPipe/\|/g;

  return $output;
}

sub template_name { 'chembox new' }
sub template_ref_name { 'chem'.shift->{pubchem_id} }
sub template_basic_fields {
  my $self = shift;

  ( my $formula_html = $self->{molecular_formula} ) =~ s{(\d+)}{<sub>$1</sub>}g;

  tie( my %fields, 'Tie::IxHash' );
  %fields = (
    ImageFile => { value => '' },
    ImageSize => { value => '' },
    IUPACName => { value => $self->{iupac_name} },
    OtherNames => { value => '' },
    Section1 => { value => sprintf( "{{Chembox Identifiers\n$EscapedPipe  %s=%s\n$EscapedPipe  %s=%s\n$EscapedPipe  %s=%s\n  }}",
      CASNo => '',
      PubChem => $self->{pubchem_id},
      SMILES => $self->{smiles},
    ) },
    Section2 => { value => sprintf( "{{Chembox Properties\n$EscapedPipe  %s=%s\n$EscapedPipe  %s=%s\n$EscapedPipe  %s=%s\n$EscapedPipe  %s=%s\n$EscapedPipe  %s=%s\n$EscapedPipe  %s=%s\n$EscapedPipe  %s=%s\n  }}",
      Formula => $formula_html,
      MolarMass => $self->{molecular_weight},
      Appearance => '',
      Density => '',
      MeltingPt => '',
      BoilingPt => '',
      Solubility => '',
    ) },
    Section3 => { value => sprintf( "{{Chembox Hazards\n$EscapedPipe  %s=%s\n$EscapedPipe  %s=%s\n$EscapedPipe  %s=%s\n  }}",
      MainHazards => '',
      FlashPt => '',
      Autoignition => '',
    ) },
  );

  return \%fields;
}

1;
