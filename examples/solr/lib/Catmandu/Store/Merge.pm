package Catmandu::Store::Merge;
# ABSTRACT: An in-memory Catmandu::Store backed by a hash
# VERSION
use Moose;
use Data::UUID;
use Clone ();
use Catmandu::Util qw(load_class);

with qw(Catmandu::Store);

has sa     => (is => 'rw', isa => 'Str' , required => 1, default => 'Simple');
has sb     => (is => 'rw', isa => 'Str' , required => 1, default => 'Simple');

# TODO --this patha/pathb stuff is nonsense and works only for 'Simple' stores
# need to fix this into something more general
has patha  => (is => 'rw', isa => 'Str' , required => 1);
has pathb  => (is => 'rw', isa => 'Str' , required => 1);

has dba    => (is => 'ro', isa => 'Object', required => 1, lazy => 1, builder => '_build_dba');
has dbb    => (is => 'ro', isa => 'Object', required => 1, lazy => 1, builder => '_build_dbb');

sub _build_dba {
    my $self = shift;

    $self->sa =~ /::/ or $self->sa("Catmandu::Store::" . $self->sa);

    warn $self->sa;

    load_class($self->sa);

    $self->sa->new({ path => $self->patha });
}

sub _build_dbb {
    my $self = shift;

    $self->sb =~ /::/ or $self->sb("Catmandu::Store::" . $self->sb);

    load_class($self->sb);

    $self->sb->new({ path => $self->pathb });
}

sub load {
    my ($self, $id) = @_;

    my $obj_a = $self->dba->load($id) || {};
    my $obj_b = $self->dbb->load($id) || {};

    my %merge = ( %$obj_a , %$obj_b );

    \%merge;
}

sub each {
    my ($self, $sub) = @_;

    $self->dba->each(sub {
        my $obj_a = shift;
        my $obj_b = $self->dbb->load( $obj_a->{_id} ) || {};
        my %merge = ( %$obj_a , %$obj_b );

        $sub->(\%merge);
    });
}

sub save {
    my ($self, $obj) = @_;
    die "not supported";
}

sub delete {
    my ($self, $id) = @_;
    die "not supported";
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

=head1 SYNOPSIS

    use Catmandu::Store::Merge;

    my $store = Catmandu::Store::Merge(patha => 'data/aleph.db' , pathb => 'data/fedora.db');

    $store->each(sub {
        my $obj = shift;

        # merged object of A and B
    });

    # Merge the objects with same '_id' field
    my $obj = $store->load('rug01:01210210212');


=head1 SEE ALSO

L<Catmandu::Store>

