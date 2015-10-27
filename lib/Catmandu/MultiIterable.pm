package Catmandu::MultiIterable;

use Catmandu::Sane;
use Catmandu::Util qw(is_string);
use Catmandu;
use Moo::Role;
use namespace::clean;

with 'Catmandu::Iterable';

has iterators => (is => 'ro', default => sub { [] });

sub generator {
    my ($self) = @_;
    sub {
        state $generators = [ map { $_->generator } @{$self->iterators} ];
        while (@$generators) {
            my $data = $generators->[0]->();
            return $data if defined $data;
            shift @$generators;
        }
        return;
    };
}

1;
__END__

=head1 NAME

Catmandu::MultiIterable - role to chain multiple iterators together

=head1 SYNOPSIS

    package MyMultiIterator
    use Moo;
    with 'Catmandu::MultiIterable';
    1;

    my $it = MyMultiIterator->new(iterators => [
        Catmandu::Importer::Mock->new,
        Catmandu::Importer::Mock->new,
    ]);

    # return all the items of each importer in turn
    $it->each(sub {
        # ...
    });

=head1 METHODS

All L<Catmandu::Iterable> methods are available.

=cut
