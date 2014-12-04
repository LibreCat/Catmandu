package Catmandu::Fix::add_to_store;

use Catmandu::Sane;
use Catmandu;
use Moo;
use Catmandu::Fix::Has;

has path       => (fix_arg => 1);
has store_name => (fix_arg => 1);
has bag_name   => (fix_opt => 1, init_arg => 'bag');
has store_args => (fix_opt => 'collect');
has store      => (is => 'lazy', init_arg => undef);
has bag        => (is => 'lazy', init_arg => undef);
has _bag_var   => (is => 'rwp', writer => '_set_bag_var', init_arg => undef);

with 'Catmandu::Fix::SimpleGetValue';

sub _build_store {
    my ($self) = @_;
    Catmandu->store($self->store_name, %{$self->store_args});
}

sub _build_bag {
    my ($self) = @_;
    defined $self->bag_name
        ? $self->store->bag($self->bag_name)
        : $self->store->bag;
}

sub emit_value {
    my ($self, $var, $fixer) = @_;
    # memoize in case called multiple times
    my $bag_var = $self->_bag_var ||
                  $self->_set_bag_var($fixer->capture($self->bag));

    "if (is_hash_ref(${var})) {" .
        "${bag_var}->add(${var});" .
    "}";
}

=head1 NAME

Catmandu::Fix::add_to_store - add matching values to a store as a side effect

=head1 SYNOPSIS

   add_to_store(authors.*, MongoDB, bag: authors, database_name: catalog)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;

