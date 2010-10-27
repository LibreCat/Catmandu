package Catmandu::Store::Simple;

use Any::Moose;
use Data::UUID;
use DBM::Deep;
use Try::Tiny;

with 'Catmandu::Store';

has path => (is => 'ro', isa => 'Str', required => 1);
has _db  => (is => 'ro', isa => 'DBM::Deep', init_arg => undef, builder => '_build_db');

sub _build_db {
    DBM::Deep->new(file => $_[0]->path, locking => 1, autoflush => 1);
}

sub save {
    my ($self, $obj) = @_;
    my $id = $obj->{_id} ||= Data::UUID->new->create_str;
    $self->_db->import({$id => $obj});
    $obj;
}

sub load {
    my ($self, $id) = @_;
    my $obj = $self->_db->get($id) or return;
    $obj->export;
}

sub each {
    my ($self, $sub) = @_;
    my $count = 0;
    while (my ($id, $obj) = each %{$self->_db}) {
        $sub->($obj->export);
        $count++;
    }
    $count;
}

sub delete {
    my ($self, $obj) = @_;
    my $id = ref $obj eq 'HASH' ? $obj->{_id} :
                                  $obj;
    $id or confess "Missing _id";
    $self->_db->delete($id);
}

sub transaction {
    my ($self, $sub) = @_;
    $self->_db->begin_work;
    try {
        $sub->($self);
        $self->_db->commit;
    } catch {
        $self->_db->rollback;
        confess $_;
    };
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
__PACKAGE__;

