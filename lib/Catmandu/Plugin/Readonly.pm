package Catmandu::Plugin::Readonly;

use Moo::Role;
use MooX::Aliases;
use Package::Stash;
use namespace::clean;

has readonly_throw_error => (is => 'ro' , default => sub { 0 });

sub BUILD {
    my ($self) = @_;
    my $name   = ref($self->store);

    # Overwrite the drop method of the Catmandu::Store implementation
    my $stash = Package::Stash->new($name);
    $stash->add_symbol(
        '&drop' => sub {
            $self->log->warn("trying to drop a readonly store");
            Catmandu::NotImplemented->throw("$name is readonly")
                if $self->readonly_throw_error;
            1;
        });
}

around add => sub {
    my ($orig,$self,$data) = @_;
    my $name = ref($self);
    $self->log->warn("trying to add to readonly store");
    Catmandu::NotImplemented->throw("$name is readonly")
        if $self->readonly_throw_error;
    $data
};

around delete => sub {
    my ($orig,$self) = @_;
    my $name = ref($self);
    $self->log->warn("trying to delete from readonly store");
    Catmandu::NotImplemented->throw("$name is readonly")
        if $self->readonly_throw_error;

    1;
};

around delete_all => sub {
    my ($orig,$self) = @_;
    my $name = ref($self);
    $self->log->warn("trying to delete_all on readonly store");
    Catmandu::NotImplemented->throw("$name is readonly")
        if $self->readonly_throw_error;
    1;
};

around drop => sub {
    my ($orig,$self) = @_;
    my $name = ref($self);
    $self->log->warn("trying to drop a readonly store");
    Catmandu::NotImplemented->throw("$name is readonly")
        if $self->readonly_throw_error;

    1;
};

1;
