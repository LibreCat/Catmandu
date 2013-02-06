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
