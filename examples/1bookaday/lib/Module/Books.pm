package Module::Books;

use Moose;

BEGIN { extends 'Catmandu::App' }

use Catmandu::Store::Simple;

has store => (
    is => 'ro',
    lazy => 1,
    default => sub {
        Catmandu::Store::Simple->new(
            path => Catmandu->conf->{db}->{blog}
        );
    },
);

sub home :GET('/') {
    my $self  = shift;
    $self->print_template('list', { list => $self->list });
}

sub list {
    my $self = shift;
    my @list = ();

    $self->store->each(sub {
        push @list, $_[0];
    });

    [ reverse @list ];
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;
