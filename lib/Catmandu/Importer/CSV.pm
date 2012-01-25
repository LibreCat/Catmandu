package Catmandu::Importer::CSV;
use Catmandu::Sane;
use Catmandu::Util qw(io);
use Text::CSV;
use Catmandu::Object
    file => { default => sub { *STDIN } },
    fields => 'r',
    quote_char => { default => sub { '"' } },
    split_char => { default => sub { ',' } };

sub _build {
    my ($self, $args) = @_;
    $self->SUPER::_build($args);
    if ($self->fields) {
        $self->_set_fields($self->fields);
    }
}

sub _set_fields {
    my ($self, $fields) = @_;

    if (!ref $fields) {
        [ split $self->split_char, $fields ];
    } elsif (ref $fields eq 'HASH') {
        [ keys %$fields ];
    } elsif (ref $fields eq 'ARRAY') {
        $fields;
    }
}

sub each {
    my ($self, $sub) = @_;

    my $file = io $self->file, 'r';

    my $csv = Text::CSV->new({
        binary     => 1,
        quote_char => $self->quote_char,
        sep_char   => $self->split_char,
    });

    my $fields = $self->fields ||
                 $self->_set_fields($csv->getline($file));

    $csv->column_names($fields);

    my $n = 0;

    while (my $obj = $csv->getline_hr($file)) {
        $sub->($obj);
        $n++;
    }

    $n;
}

=head1 NAME

Catmandu::Importer::CSV - Package that imports CSV data

=head1 SYNOPSIS

    use Catmandu::Importer::CSV;

    my $importer = Catmandu::Importer::CSV->new(file => "/foo/bar.csv");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 METHODS

=head2 new(file => $filename, fields => \@fields, quote_char => "\"", split_char => ",")

Create a new CSV importer for $filename. Use STDIN when no filename is given. The
object fields are read from the CSV header line or given via the 'fields' parameter.
Strings in CSV are quoted by 'quote_char' and fields are split by 'split_char'.

=head2 each(&callback)

The each method imports the data and executes the callback function for
each item imported. Returns the number of items imported or undef on 
failure.

=cut

1;
