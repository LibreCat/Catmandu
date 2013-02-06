package Catmandu::FixCondition::any_match;

use Catmandu::Sane;
use Catmandu::Util qw(:data);
use Moo;

with 'Catmandu::FixCondition';

has path    => (is => 'ro', required => 1);
has key     => (is => 'ro', required => 1);
has pattern => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $pattern) = @_;
    my ($p, $key) = parse_data_path($path);
    $orig->($class, path => $p, key => $key, pattern => $pattern);
};

sub is_fixable {
    my ($self, $data) = @_;
    my $key = $self->key;
    my $pattern = $self->pattern;
    for my $match (grep ref, data_at($self->path, $data)) {
        for my $val (get_data($match, $key)) {
            return 1 if $val =~ m{$pattern};
        }
    }
    0;
}

=head1 NAME

Catmandu::FixCondition::any_match - only execute fixes if any path value matches the given regex

=head1 SYNOPSIS

   # uppercase the value of field 'foo' if field 'oogly' has the value 'doogly'
   if_any_match('oogly', 'doogly');
   upcase('foo'); # foo => 'BAR'
   end()

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
