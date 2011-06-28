package Catmandu::Exporter::BibTeX;
use Catmandu::Sane;
use Catmandu::Util qw(io quack);
use Catmandu::Object file => { default => sub { *STDOUT } };
use LaTeX::Encode;

my @bibtex_tags = qw(
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
);

my %bibtex_join = (
    author   => ' and ',
    editor   => ' and ',
    language => ',',
    keyword  => ',',
);

sub _add {
    my ($self, $file, $obj) = @_;

    my $type    = $obj->{_type} || 'misc';
    my $citekey = $obj->{_citekey};

    for my $tag (keys %bibtex_join) {
        my $val = $obj->{$tag};
        if ($val && ref($val) eq 'ARRAY') {
            $obj->{$tag} = join $bibtex_join{$tag}, @$val;
        }
    }

    print $file "\@$type\{$citekey,\n";

    for my $tag (@bibtex_tags) {
        my $val = $obj->{$tag} || next;
        printf $file "  %-12s = {%s},\n", $tag, latex_encode($val);
    }

    print $file "}\n\n";
}

sub add {
    my ($self, $obj) = @_;

    my $file = io $self->file, 'w';

    if (quack $obj, 'each') {
        my $n = 0;
        $obj->each(sub {
            $self->_add($file, $_[0]);
            $n++;
        });
        return $n;
    }

    $self->_add($file, $obj);
    1;
}

1;
