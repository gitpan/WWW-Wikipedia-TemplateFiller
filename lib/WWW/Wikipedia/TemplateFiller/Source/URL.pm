package WWW::Wikipedia::TemplateFiller::Source::URL;
use base 'WWW::Wikipedia::TemplateFiller::Source';

use warnings;
use strict;

use WWW::Mechanize;
use Tie::IxHash;
use URI;

sub new {
  my( $pkg, %attrs ) = @_;
  $attrs{__mech} = new WWW::Mechanize( agent => 'Wikipedia template filler (diberri)' );
  return bless \%attrs, $pkg;
}

sub __mech { shift->{__mech} }

sub get {
  my( $self, $url ) = @_;

  $self->__mech->get($url);

  return $self->__source_obj( {
    url => $url,
    title => $self->__mech->title || URI->new( $url )->host || '',
  } );
}

sub template_name { 'cite web' }
sub template_ref_name { 'url'.shift->{title} }
sub template_basic_fields {
  my $self = shift;

  ( my $url_enc = $self->{url} ) =~ s/\s/+/g;  

  tie( my %fields, 'Tie::IxHash' );
  %fields = (
    -url => $url_enc,
    -title => $self->{title},
    '+author' => '',
    '+authorlink' => '',
    '+coauthors' => '',
    '+date' => '',
    -format => '',
    -work => '',
    '+publisher' => '',
    '+pages' => '',
    '+language' => '',
    '+archiveurl' => '',
    '+archivedate' => '',
    '+quote' => '',
    -accessdate => '',
  );

  return \%fields;
}

sub template_output_fields {
  my( $self, %args ) = @_;

  tie( my %fields, 'Tie::IxHash' );
  $fields{accessdate} = $self->__today_and_now if $args{add_accessdate};

  return \%fields;
}

1;
