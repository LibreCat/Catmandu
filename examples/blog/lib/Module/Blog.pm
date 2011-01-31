package Module::Blog;

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
    $self->print_template('blog', { blog => $self->list });
}

sub save :POST('/') {
    my $self  = shift;
    my $msg   = $self->request->param('msg');

    my $date = localtime time;

    $self->store->save({
        date => $date,
        msg  => $msg,
    });

    $self->print_template('blog', { blog => $self->list });
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

