package Catmandu::Store::Hash;

use namespace::autoclean;
use Moose;
use Data::UUID;
use Clone ();

with qw(Catmandu::Store);

has hash => (is => 'rw', isa => 'HashRef', required => 1, default => sub { {} });

sub load {
    my ($self, $id) = @_;
    $id = $self->need_id($id);
    my $obj = $self->hash->{$id} or return;
    Clone::clone($obj);
}

sub each {
    my ($self, $sub) = @_;
    my $n = 0;
    while ( my ($id, $obj) = each(%{$self->hash}) ) {
        $sub->(Clone::clone($obj));
        $n++;
    }
    $n;
}

sub save {
    my ($self, $obj) = @_;
    my $id = $obj->{$self->id_field} ||= Data::UUID->new->create_str;
    $self->hash->{$id} = Clone::clone($obj);
    $obj;
}

sub delete {
    my ($self, $id) = @_;
    delete $self->hash->{$self->need_id($id)};
}

__PACKAGE__->meta->make_immutable;

1;

