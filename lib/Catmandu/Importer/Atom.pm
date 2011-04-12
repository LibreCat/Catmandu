package Catmandu::Importer::Atom;
# ABSTRACT: Streaming YAML importer
# VERSION
use Moose;
use XML::Atom::Client;

with qw(
    Catmandu::Importer
);

has url => (
    is => 'ro',
    isa => 'Str',
);

sub default_attribute {
    'url';
}

sub each {
    my ($self, $sub) = @_;
    my $n = 0;
	
    my $client = new XML::Atom::Client;
    my $feed   = $client->getFeed($self->url);

    for my $entry ($feed->entries) {
	my $id      = $entry->id;
        my $published = $entry->published;
        my $link    = $entry->link->href;
        my $author  = $entry->author->name;
        my $content = $entry->content->body;

	$sub->({
          _id     => $id,
	  published => $published,
	  author  => $author,
	  link    => $link,
	  content => $content,
	});
    }
 
    $n;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

