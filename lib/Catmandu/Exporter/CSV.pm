package Catmandu::Exporter::CSV;
use Catmandu::Sane;
use Catmandu::Util qw(io quack);
use Text::CSV;
use Catmandu::Object
    file => { default => sub { *STDOUT } },
    fields => 'r',
    quote_char => { default => sub { '"' } },
    split_char => { default => sub { ',' } };

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

sub _build {
    my ($self, $args) = @_;
    $self->SUPER::_build($args);
    if ($self->{fields}) {
        $self->{fields} = $self->_set_fields($self->{fields});
    }
}

sub add {
    my ($self, $obj) = @_;

    my $file = io $self->file, 'w';

    my $fields = $self->fields;

    my $csv = Text::CSV->new({
        binary     => 1,
        quote_char => $self->quote_char,
        sep_char   => $self->split_char,
    });

    if ($fields) {
        $csv->print($file, $fields);
    }

    my $add = sub {
        my $o = $_[0];

        if (! $fields) {
            $fields = $self->_set_fields($o);
            $csv->print($file, $fields);
        }

        print $file "\n";
        my $row = [ map { $o->{$_} } @$fields ];
        $csv->print($file, $row);
    };

    if (quack $obj, 'each') {
        return $obj->each($add);
    }

    $add->($obj);
    1;
}

1;
