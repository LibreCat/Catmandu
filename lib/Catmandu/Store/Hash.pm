package Catmandu::Store::Hash;
use Data::UUID;
use Clone;
use Catmandu::Class;
use parent qw(
    Catmandu::Modifiable
    Catmandu::Pluggable
);

sub plugin_namespace { 'Catmandu::Store::Plugin' }

sub build {
    my ($self, $args) = @_;
    $self->{hash} = $args->{hash} || {};
}

sub load {
    my ($self, $id) = @_;
    $id = $id->{_id} if ref $id eq 'HASH';
    $id or confess "_id missing";
    my $obj = $self->{hash}{$id};
    $obj or return;
    Clone::clone($obj);
}

sub each {
    my ($self, $sub) = @_;
    my $n = 0;
    while (my ($id, $obj) = each(%{$self->{hash}})) {
        $sub->(Clone::clone($obj));
        $n++;
    }
    $n;
}

sub save {
    my ($self, $obj) = @_;
    my $id = $obj->{_id} ||= Data::UUID->new->create_str;
    $self->{hash}{$id} = Clone::clone($obj);
    $obj;
}

sub delete {
    my ($self, $id) = @_;
    $id = $id->{_id} if ref $id eq 'HASH';
    $id or confess "_id missing";
    delete $self->{hash}{$id};
}

1;
