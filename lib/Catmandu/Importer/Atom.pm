package Catmandu::Importer::Atom;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(trim);
use XML::Atom::Client;
use Moo;

with 'Catmandu::Importer';

my $ENTRY_ATTRS    = [qw(id title published updated summary rights)];
my $CONTENT_ATTRS  = [qw(mode type body)];
my $PERSON_ATTRS   = [qw(name email uri url homepage)];
my $LINK_ATTRS     = [qw(rel href hreflang title type length)];
my $CATEGORY_ATTRS = [qw(term label scheme)];

has url     => (is => 'ro', required => 1);
has entries => (is => 'ro', init_arg => undef, lazy => 1, builder => '_build_entries');

sub _build_entries {
    my $self = $_[0];
    my $feed = XML::Atom::Client->new->getFeed($self->url);
    [map {
        my $entry = $_;
        my $entry_data = {};
        for my $key (@$ENTRY_ATTRS) {
            $entry_data->{$key} = trim($entry->$key || next) || next;
        }
        if (my $content = $entry->content) {
            for my $key (@$CONTENT_ATTRS) {
                $entry_data->{content}{$key} = trim($content->$key || next) || next;
            }
        }
        if (my $author = $entry->author) {
            for my $key (@$PERSON_ATTRS) {
                $entry_data->{author}{$key} = trim($author->$key || next) || next;
            }
        }
        if (my $contributor = $entry->contributor) {
            for my $key (@$PERSON_ATTRS) {
                $entry_data->{contributor}{$key} = trim($contributor->$key || next) || next;
            }
        }
        if (my @category = $entry->category) {
            $entry_data->{category} = [map {
                my $category = $_;
                my $category_data = {};
                for my $key (@$CATEGORY_ATTRS) {
                    $category_data->{$key} = trim($category->$key || next) || next;
                }
                $category_data;
            } @category];
        }
        if (my @links = $entry->link) {
            $entry_data->{link} = [map {
                my $link = $_;
                my $link_data = {};
                for my $key (@$LINK_ATTRS) {
                    $link_data->{$key} = trim($link->$key || next) || next;
                }
                $link_data;
            } @links];
        }
        for my $node ($entry->elem->childNodes) {
            my $uri = $node->namespaceURI;
            next if (! $uri || $uri eq 'http://purl.org/atom/ns#');
            my $name  = $node->nodeName;
            my $value = $node->textContent;
            $entry_data->{$name} = $value;
        }
        $entry_data;
    } $feed->entries];
}

sub to_array { goto &entries }

sub generator {
    my ($self) = @_;
    my $n = 0;
    sub {
        $self->entries->[$n++];
    };
}

=head1 NAME

Catmandu::Importer::Atom - Package that imports Atom feeds

=head1 SYNOPSIS

    use Catmandu::Importer::Atom;

    my $importer = Catmandu::Importer::Atom->new(url => "...");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 METHODS

=head2 new(url => URL,[entries => [qw(...)])

Create a new Atom importer for the URL. Optionally provide a entries parameter with the
feed items you want to import.

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. The
Catmandu::Importer::Atom methods are not idempotent: Atom feeds can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
