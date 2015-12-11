package Catmandu::TabularExporter;

use Catmandu::Sane;

our $VERSION = '0.9505';

use Catmandu::Util qw(:is);
use Moo::Role;

sub _coerce_array {
    my $fields = $_[0];
    if (ref $fields eq 'ARRAY') { return $fields }
    if (ref $fields eq 'HASH')  { return [sort keys %$fields] }
    [split ',', $fields];
}

use namespace::clean;

with 'Catmandu::Exporter';

has fields => (
    is => 'rwp',
    coerce => \&_coerce_array,
);

has columns => (
    is => 'rwp',
    coerce => \&_coerce_array,
);

has collect_fields => (
    is => 'ro',
);

around add => sub {
    my ($orig, $self, $data) = @_;
    $self->_set_fields([sort keys %$data]) unless $self->fields;
    $orig->($self, $data);
};

around add_many => sub {
    my ($orig, $self, $many) = @_;

    if ($self->collect_fields && !$self->fields) {
        my $coll;

        if (is_array_ref($many)) {
            $coll = $many;
        } elsif (is_hash_ref($many)) {
            $coll = [$many];
        } else {
            if (is_invocant($many)) {
                $many = check_able($many, 'generator')->generator;
            }
            check_code_ref($many);
            $coll = [];
            while (defined(my $data = $many->())) {
                push @$coll, $data;
            }
        }

        my %keys;
        for my $data (@$coll) {
            for my $key (keys %$data) {
                $keys{$key} ||= 1;
            }
        }
        $self->_set_fields([sort keys %keys]);

        $many = $coll;
    }

    $orig->($self, $many);
};

1;

__END__

=pod

=head1 NAME

Catmandu::TabularExporter - base role for exporters that export a tabular format like CSV

=cut
