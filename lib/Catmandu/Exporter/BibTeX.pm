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

=head1 NAME

Catmandu::Exporter::BibTeX - a BibTeX exporter

=head1 SYNOPSIS

    use Catmandu::Exporter::BibTeX;

    my $exporter = Catmandu::Exporter::BibTeX->new(fix => 'myfix.txt');

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    $exporter->add({
     _type    => 'book',
     _citekey => '389-ajk0-1',
     title    => 'the Zen of {CSS} design',
     author   => ['Dave Shea','Molley E. Holzschlag'],
     isbn     => '0-321-30347-4'
    });

    printf "exported %d objects\n" , $exporter->count;

=head1 DESCRIPTION

The BibTeX exporter requires as input a Perl hash (or a fix) containing BibTeX
fields and values as a string or array reference.

Two special fields can be set in the Perl hash:

 _type : to describe the document type (article, book, ...)
 _citekey : to describt the citation key

=head1 SUPPORTED FIELDS

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


=head1 SEE ALSO

L<Catmandu::Exporter>

=cut

1;
