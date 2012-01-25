package Catmandu::Importer::Atom;

use Catmandu::Sane;
use Catmandu::Util qw(trim);
use Moo;
use XML::Atom::Client;

with 'Catmandu::Importer';

my $ENTRY_ATTRS   = [qw(id published updated summary)];
my $CONTENT_ATTRS = [qw(mode type body)];
my $PERSON_ATTRS  = [qw(name email uri url homepage)];
my $LINK_ATTRS    = [qw(rel href hreflang title type length)];

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

        $entry_data;
    } $feed->entries];
}

sub generator {
    my ($self) = @_;
    sub {
        state $n = 0;
        $self->entries->[$n++];
    };
}

1;
