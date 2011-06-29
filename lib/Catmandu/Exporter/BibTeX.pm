package Catmandu::Exporter::BibTeX;
use Catmandu::Sane;
use Catmandu::Util qw(io quack);
use Catmandu::Object file => { default => sub { *STDOUT } };
use LaTeX::Encode;

my $tags = [qw(
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

my $join = {
    author   => ' and ',
    editor   => ' and ',
    language => ',',
    keyword  => ',',
};

sub add {
    my ($self, $obj) = @_;

    my $file = io $self->file, 'w';

    my $add = sub {
        my $o = $_[0];

        my $type    = $o->{_type} || 'misc';
        my $citekey = $o->{_citekey};

        for my $tag (keys %$join) {
            my $val = $o->{$tag};
            if ($val && ref($val) eq 'ARRAY') {
                $o->{$tag} = join $join->{$tag}, @$val;
            }
        }

        print $file "\@$type\{$citekey,\n";

        for my $tag (@$tags) {
            if (my $val = $o->{$tag}) {
                printf $file "  %-12s = {%s},\n", $tag, latex_encode($val);
            }
        }

        print $file "}\n\n";
    };

    if (quack $obj, 'each') {
        return $obj->each($add);
    }

    $add->($obj);
    1;
}

1;
