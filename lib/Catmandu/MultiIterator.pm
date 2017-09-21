package Catmandu::MultiIterator;

use Catmandu::Sane;

our $VERSION = '1.0605';

use Role::Tiny::With;
use namespace::clean;

with 'Catmandu::Iterable';

sub new {
    my ($class, @iterators) = @_;
    my $self = \@iterators;
    bless $self, $class;
}

sub generator {
    my ($self) = @_;
    sub {
        state $generators = [map {$_->generator} @$self];
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

=pod

=head1 NAME

Catmandu::MultiIterator - chain multiple iterators together

=head1 SYNOPSIS

    my $it = Catmandu::MultiIterator->new(
        Catmandu::Importer::Mock->new,
        Catmandu::Importer::Mock->new,
    );

    # return all the items of each importer in turn
    $it->each(sub {
        # ...
    });

=head1 METHODS

All L<Catmandu::Iterable> methods are available.

=cut
