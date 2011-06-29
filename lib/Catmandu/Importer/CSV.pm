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

1;
