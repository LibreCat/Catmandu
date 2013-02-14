package Catmandu::FixCondition::exists;

use Catmandu::Sane;
use Catmandu::Util qw(:data);
use Moo;

with 'Catmandu::FixCondition';

has path => (is => 'ro', required => 1);
has key  => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path) = @_;
    my ($p, $key) = parse_data_path($path);
    $orig->($class, path => $p, key => $key);
};

sub is_fixable {
    my ($self, $data) = @_;
    my $key = $self->key;
    for my $match (grep ref, data_at($self->path, $data)) {
        return 1 if get_data($match, $key);
    }
    0;
}

sub emit {
    my ($self, $fixer) = @_;
    my $path_to_key = $self->path;
    my $key = $self->key;
    $fixer->emit_walk_path($fixer->var, $path_to_key, sub {
        my $var = shift;
        if ($key =~ /^\d+$/) {
            return "is_hash_ref(${var}) && exists(${var}->{\"${key}\"}) || is_array_ref(${var}) && \@{${var}} > ${key}";
        }
        $key = $fixer->emit_string($key);
        "is_hash_ref(${var}) && exists(${var}->{${key}})";
    });
}

=head1 NAME

Catmandu::FixCondition::exists - only execute fixes if the path exists

=head1 SYNOPSIS

   # uppercase the value of field 'foo' if the field 'oogly' exists
   if_exists('oogly');
   upcase('foo'); # foo => 'BAR'
   end()
   # inverted
   unless_exists('oogly');
   upcase('foo'); # foo => 'bar'
   end()

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
