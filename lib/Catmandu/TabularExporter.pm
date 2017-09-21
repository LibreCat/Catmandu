package Catmandu::TabularExporter;

use Catmandu::Sane;

our $VERSION = '1.0605';

use Catmandu::Util qw(:is :check);
use Moo::Role;

sub _coerce_array {
    my $fields = $_[0];
    if (ref $fields eq 'ARRAY') {return $fields}
    if (ref $fields eq 'HASH') {return [sort keys %$fields]}
    [split ',', $fields];
}

use namespace::clean;

with 'Catmandu::Exporter';

has fields => (is => 'rwp', coerce => \&_coerce_array,);

has columns => (is => 'rwp', coerce => \&_coerce_array,);

has collect_fields => (is => 'ro',);

has header => (is => 'ro', default => sub {1});

around add => sub {
    my ($orig, $self, $data) = @_;
    $self->_set_fields($data) unless $self->fields;
    $orig->($self, $data);
};

around add_many => sub {
    my ($orig, $self, $many) = @_;

    if ($self->collect_fields && !$self->fields) {
        my $coll;

        if (is_array_ref($many)) {
            $coll = $many;
        }
        elsif (is_hash_ref($many)) {
            $coll = [$many];
        }
        else {
            if (is_invocant($many)) {
                $many = check_able($many, 'generator')->generator;
            }
            check_code_ref($many);
            $coll = [];
            while (defined(my $data = $many->())) {
                push @$coll, $data;
            }
        }

        my $keys = {};
        for my $data (@$coll) {
            for my $key (keys %$data) {
                $keys->{$key} ||= 1;
            }
        }
        $self->_set_fields($keys);

        $many = $coll;
    }

    $orig->($self, $many);
};

1;

__END__

=pod

=head1 NAME

Catmandu::TabularExporter - base role for tabular exporters like CSV

=head1 DESCRIPTION

See L<Catmandu::Exporter> for the base functionality of this role. This role
adds some functionality tailored to tabular or columnar exporters.

=head1 CONFIGURATION

=over

=item fields

The fields to be mapped. Can be an arrayref, example hashref or comma
separated string. If missing, the fields of the first record encountered will
be used. If C<collect_fields> is true, all fields names in the record stream
will be collected first.

=item columns

Optional custom column labels. Can be an arrayref, example hashref or comma
separated string.

=item collect_fields

See C<fields> for a description. Note that this option will cause all records
in the stream to be buffered in memory.

=item header

Include a header with column names. Enabled by default.

=back

=cut

