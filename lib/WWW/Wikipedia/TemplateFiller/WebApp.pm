package WWW::Wikipedia::TemplateFiller::WebApp;
use base 'CGI::Application';

use WWW::Wikipedia::TemplateFiller;
use Tie::IxHash;

# Access key for ISBNdb.com's API
my $ISBNdb_Access_Key = 'J9M36CIE';

=head2 setup

Sets up the app.

=cut

sub setup {
  my $self = shift;
  $self->mode_param('f');
  $self->start_mode('form');
  $self->run_modes(
    form => 'make_form',
  );
  $self->header_add( -charset => 'utf-8' );
}

=head2 make_form

Makes the page.

=cut

sub make_form {
  my $self = shift;
  my $q = $self->query;
  my %params = $self->query_params;

  my $type = $q->param('type');
  my $id = $q->param('id');

  my $error_message = '';
  if( $type and !exists $self->keyed_data_sources->{ $type } ) {
    $error_message = "No such template type.";
    $id = '';
  }
  
  my( $filler, $source, $template_markup );
  my $source_url = '';
  if( $type and $id ) {
    no warnings;
    $WWW::Scraper::ISBN::ISBNdb_Driver::ACCESS_KEY = $ISBNdb_Access_Key;

    $filler = new WWW::Wikipedia::TemplateFiller();
    $source = $filler->get( $type => $id );
    if( $source ) {
      $template_markup = $source->fill(%params)->output(%params);
    } else {
      $error_message = "Could not find requested source.";
    }
  }

  my $format = $q->param('format') || '';

  if( $format eq 'xml' ) {
    my $xml = '';
    my $writer = new XML::Writer( OUTPUT => \$output );
    $writer->startTag( 'wikitool', application => 'cite' );

    $writer->startTag( 'query' );
      $writer->startTag( 'id', type => $type );
      $writer->characters( $id );
      $writer->endTag();
    $writer->endTag();

    $writer->startTag( 'response', status => $template_markup ? 'ok' : 'error' );
    if( $template_markup ) {
      $writer->startTag('source');
      $writer->characters( $source_url );
      $writer->endTag();

      $writer->startTag( 'content', template => 'Template:'.$template_name );
      $writer->characters( $template_markup );
      $writer->endTag();

      $writer->startTag('paramlist');
      while( my( $k, $v ) = each %query_params ) {
        $writer->startTag( 'param', name => $k );
        $writer->characters($v);
        $writer->endTag();
      }
      $writer->endTag();
    } else {
      $writer->startTag( 'error' );
      $writer->characters( 'Citation could not be generated, perhaps because the requested reference could not be found.' );
      $writer->endTag();
    }

    $writer->endTag();
    $writer->endTag();
    $writer->end();

    return $xml;
  }

  my $data_sources = $self->data_sources;
  my $selected_type = $type || 'pubmed_id';
  foreach ( @$data_sources ) {
    $_->{selected} = ( $selected_type eq $_->{source} );
  }

  my $temp = $self->load_template( 'start.html' );
  $temp->param(
    error_message => $error_message,
    template_markup => $template_markup,
    data_sources => $data_sources,
    checkbox_options => $self->checkbox_options,
    source_url => $source_url,
    $self->query_params,
  );

  my $output = '';
  $output .= $temp->output;

  return $output;
}

=head2 load_template

Loads the specified template.

=cut

sub load_template {
  my( $self, $file ) = @_;
  return $self->load_tmpl( $file, die_on_bad_params => 0, loop_context_vars => 1, cache => 1 );
}

=head2 keyed_data_sources

Returns data sources by key.

=cut

sub keyed_data_sources {
  my %keyed;

  foreach my $ds ( @{ shift->data_sources } ) {
    $keyed{ $ds->{source} } = $ds;
  }
  
  return \%keyed;
}

=head2 data_sources

Returns all data sources in an array reference.

=cut

sub data_sources {
  return [
    { name => 'DrugBank ID', source => 'drugbank_id', template => 'drugbox',      example_id => 'DB00328' },
    { name => 'HGNC ID',     source => 'hgnc_id',     template => 'protein',      example_id => '12403' },
    { name => 'ISBN',        source => 'isbn',        template => 'cite_book',    example_id => '0721659446' },
    { name => 'PubMed ID',   source => 'pubmed_id',   template => 'cite_journal', example_id => '123455' },
    { name => 'PubChem ID',  source => 'pubchem_id',  template => 'chembox_new',  example_id => '2244' },
    { name => 'URL',         source => 'url',         template => 'cite_web',     example_id => 'http://en.wikipedia.org' },
  ];
}

=head2 query_params

Returns all relevant query params passed in this HTTP request.

=cut

sub query_params {
  my $self = shift;
  my $q = $self->query;
  my $params = $self->params;

  return map {
    $_ => $q->param($_) || '' # was 0 instead of ''
  } keys %$params;
}

=head2 params

Returns all params.

=cut

sub params {
  tie( my %params, 'Tie::IxHash' );

  %params = (
    type => 0,
    id => '',
    vertical => 'Fill vertically',
    extended => 'Show extended fields',
    add_param_space => 'Pad parameter names and values',
    add_accessdate => 'Add access date (if relevant)',
    add_ref_tag => 'Add ref tag',
    add_text_url => 'Add URL (if available)',
    dont_strip_trailing_period => "Don't strip trailing period from article title",
    dont_use_etal => "Don't use <i>et al</i> for author list",
    link_journal => 'Link journal title',
  );

  return \%params;
}

=head2 checkbox_options

Same as C<params> but suitable output for L<CGI::checkbox> calls.

=cut

sub checkbox_options {
  my $self = shift;

  my $params = $self->params;
  my %qp = $self->query_params;

  my @options;
  foreach my $p ( keys %$params ) {
    push @options, { name => $p, value => 1, checked => $qp{$p}, id => $p, label => $params->{$p} };
  }

  shift @options for 1..2;

  return \@options;
}

1;
