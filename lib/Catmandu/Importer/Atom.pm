package Catmandu::Importer::Atom;
use Catmandu::Sane;
use Catmandu::Object url => 'r';
use XML::Atom::Client;

sub each {
    my ($self, $sub) = @_;

    my $feed = XML::Atom::Client->new->getFeed($self->url);

    my $n = 0;

    for my $entry ($feed->entries) {
        $sub->({
          _id       => $entry->id,
          published => $entry->published,
          link      => $entry->link->href,
          author    => $entry->author->name,
          content   => $entry->content->body,
        });
    }

    $n;
}

1;
