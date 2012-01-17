package Catmandu::Exporter::BibTeX;

use Catmandu::Sane;
use Moo;
use LaTeX::Encode;

with 'Catmandu::Exporter';

my $TAGS = [qw(
    abstract
    address
    author
    booktitle
    chapter
    edition
    editor
    eprint
    howpublished
    institution
    isbn
    issn
    journal
    keyword
    language
    location
    month
    note
    number
    organization
    pages
    publisher
    school
    series
    title
    type
    url
    volume
    year
)];

my $JOIN = {
    author   => ' and ',
    editor   => ' and ',
    language => ',',
    keyword  => ',',
};

sub add {
    my ($self, $data) = @_;
    my $fh = $self->fh;

    my $type = $data->{_type} || 'misc';
    my $citekey = $data->{_citekey} || $data->{_id} || $self->count;

    for my $tag (keys %$JOIN) {
        my $val = $data->{$tag};
        if ($val && ref($val) eq 'ARRAY') {
            $data->{$tag} = join $JOIN->{$tag}, @$val;
        }
    }

    print $fh "\@$type\{$citekey,\n";

    for my $tag (@$TAGS) {
        if (my $val = $data->{$tag}) {
            printf $fh "  %-12s = {%s},\n", $tag, latex_encode($val);
        }
    }

    print $fh "}\n\n";
}

1;
