package Catmandu::Plugin::Readonly;

our $VERSION = '1.2025';

use Moo::Role;
use MooX::Aliases;
use Package::Stash;
use namespace::clean;

sub BUILD {
    my ($self) = @_;

    if ($self->store->does('Catmandu::Droppable')) {
        Role::Tiny->apply_roles_to_object($self->store,
            qw(Catmandu::Plugin::Readonly::Droppable));
    }
    if ($self->does('Catmandu::Droppable')) {
        Role::Tiny->apply_roles_to_object($self,
            qw(Catmandu::Plugin::Readonly::Droppable));
    }
    if ($self->does('Catmandu::Searchable')) {
        Role::Tiny->apply_roles_to_object($self,
            qw(Catmandu::Plugin::Readonly::Searchable));
    }
}

around add => sub {
    my ($orig, $self, $data) = @_;
    my $pkg = ref($self);
    $self->log->warn("trying to add to readonly store");
    my $err = Catmandu::NotImplemented->new("$pkg is readonly");
    return undef, $err;
};

around delete => sub {
    my ($orig, $self) = @_;
    my $pkg = ref($self);
    $self->log->warn("trying to delete from readonly store");
    my $err = Catmandu::NotImplemented->new("$pkg is readonly");
    return undef, $err;
};

around delete_all => sub {
    my ($orig, $self) = @_;
    my $pkg = ref($self);
    $self->log->warn("trying to delete_all on readonly store");
    my $err = Catmandu::NotImplemented->new("$pkg is readonly");
    return undef, $err;
};

1;

__END__

=pod

=head1 NAME

Catmandu::Plugin::Readonly - Make stores or bags read-only

=head1 SYNOPSIS

 $ cat catmandu.yml
 ---
 store:
  test:
    package: MongoDB
    options:
      default_plugins: [ 'Readonly']

=head1 DESCRIPTION

The Catmandu::Plugin::Readonly will transform a Catmandu::Store or a Catmandu::Bag
in read-only mode: all writes, deletes and drops will be ignored.

This command will work on L<Catmandu::Store>
implementations.

=head1 SEE ALSO

L<Catmandu::Store>, L<Catmandu::Bag>

=cut
