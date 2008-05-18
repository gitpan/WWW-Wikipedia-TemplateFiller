package WWW::Wikipedia::TemplateFiller::Source::PubmedId;
use base 'WWW::Wikipedia::TemplateFiller::Source';

use warnings;
use strict;
use Carp;

use WWW::Search;
use HTML::Entities;

my %Journals = (
  Science => 'Science (journal)',
);

sub new {
  my( $pkg, %attrs ) = @_;
  $attrs{__search} = new WWW::Search('PubMedLite');
  return bless \%attrs, $pkg;
}

sub get {
  my( $self, $pmid ) = @_;

  $self->{__search}->native_query($pmid);
  my $article = $self->{__search}->next_result;

  # Strip trailing period from title if requested
  unless( $self->{dont_strip_trailing_period} ) {
    $article->{title} =~ s/\.$//;
  }

  my $lang = $article->{language_name} eq 'English' ? undef : $article->{language_name};

  my @authors = ref $article->{authors} ? @{ $article->{authors} } : ();
  my $author_list;
  if( @authors > 6 and !$self->{dont_use_etal} ) {
    $author_list = join( ', ', @authors[0..2]) . ", ''et al''";
  } else {
    $author_list = join ', ', @authors;
  }

  for my $field ( qw/ title journal_abbreviation / ) {
    $article->{$field} =~ s/\=/encode_entities('&#61;')/ge;
  }

  return $self->__source_obj( {
    __source_url => $article->url,
    %$article,
    author => $author_list,
    language => $lang,
  } );
}

sub template_name { 'cite journal' }
sub template_ref_name { 'pmid'.shift->{pmid} }
sub template_basic_fields {
  my $self = shift;

  my $journal_title = $self->{journal_abbreviation};
  $journal_title = $Journals{$journal_title} if exists $Journals{$journal_title};

  my $pages = $self->{page};
  my $ndash = decode_entities('&ndash;');
  $pages =~ s{\-}{$ndash}g;

  tie( my %fields, 'Tie::IxHash' );
  %fields = (
    -author  => $self->{author},
    -title   => $self->{title},
    language => $self->{language},
    -journal => $journal_title,
    -volume  => $self->{volume},
    -issue   => $self->{issue},
    -pages   => $pages,
    -year    => $self->{year},
    -pmid    => $self->{pmid},
  );

  my $doi = $self->{doi};
  my $url = $self->{text_url};
  $url = '' if $doi;

  $fields{-doi} = $doi;
  $fields{-url} = $url;
  $fields{'+issn'} = '';

  return \%fields;
}

sub template_output_fields {
  my( $self, %args ) = @_;

  my $add_accessdate = exists $args{add_accessdate} ? $args{add_accessdate} : 1;
  my $link_journal = $args{link_journal};

  tie( my %fields, 'Tie::IxHash' );
  $fields{accessdate} = $self->__today_and_now if $add_accessdate;
  $fields{url} = $self->{text_url} if $args{add_text_url};
  $fields{journal} = '[['.$self->{basic_fields}->{journal}.']]' if $args{link_journal};

  return \%fields;
}

1;
