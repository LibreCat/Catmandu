package Catmandu::Store::Mock;

use Mouse;
use Data::UUID;
use Storable;

has 'file' => (is => 'ro', required => 1);

sub BUILD {
    my $self = $_[0];
    if (! -r $self->file) {
        Storable::nstore({}, $self->file);
    }
}

sub load {
    my ($self, $id) = @_;
    Storable::retrieve($self->file)->{$id};
}

sub save {
    my ($self, $obj) = @_;

    if (ref $obj ne 'HASH') {
        confess "Object must be a hashref";
    }

    my $id = $obj->{_id} ||= Data::UUID->new->create_str;

    my $store = Storable::retrieve($self->file);
    $store->{$id} = $obj;
    Storable::nstore($store, $self->file);

    $obj;
}

sub delete {
    my ($self, $obj) = @_;

    if (ref $obj ne 'HASH') {
        confess "Object must be a hashref";
    }

    my $id = $obj->{_id};
    my $store = Storable::retrieve($self->file);

    if (exists $store->{$id}) {
        delete $store->{$id};
        Storable::nstore($store, $self->file);
        return 1;
    }
    0;
}

sub each {
    my ($self, $block) = @_;

    my $store = Storable::retrieve($self->file);
    my $count = 0;

    while ( my ($key, $obj) = each(%$store) ) {
        $block->($obj);
        $count++;
    }
    $count;
}

sub done {
    1;
}

__PACKAGE__->meta->make_immutable;
no Mouse;

__END__

=head1 NAME

 Catmandu::Store::Mock - A mock store for bibliographic
 data structures.

=head1 SYNOPSIS

 Catmandu::Store::Mock->new(file => $path);

=head1 DESCRIPTION

 See L<Catmandu::Store>.

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
