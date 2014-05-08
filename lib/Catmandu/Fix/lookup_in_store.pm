package Catmandu::Fix::lookup_in_store;

use Catmandu::Sane;
use Catmandu;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path       => (fix_arg => 1);
has store_name => (fix_arg => 1);
has bag_name   => (fix_opt => 1, init_arg => 'bag');
has default    => (fix_opt => 1);
has delete     => (fix_opt => 1);
has store_args => (fix_opt => 'collect');
has store      => (is => 'lazy', init_arg => undef);
has bag        => (is => 'lazy', init_arg => undef);

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

sub emit {
    my ($self, $fixer) = @_;
    my $path     = $fixer->split_path($self->path);
    my $key      = pop @$path;
    my $bag_var  = $fixer->capture($self->bag);
    my $delete   = $self->delete;
    my $default  = $self->default;

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $val_var = shift;
            my $val_index = shift;
            my $bag_val_var = $fixer->generate_var;
            my $perl = "if (is_value(${val_var}) && defined(my ${bag_val_var} = ${bag_var}->get(${val_var}))) {" .
                "${val_var} = ${bag_val_var};" .
            "}";
            if ($delete) {
                $perl .= "else {";
                if (defined $val_index) { # wildcard: only delete the value where the lookup failed
                    $perl .= "splice(\@{${var}}, ${val_index}--, 1);";
                } else {
                    $perl .= $fixer->emit_delete_key($var, $key);
                }
                $perl .= "}";
            } elsif (defined $default) {
                $perl .= "else {" .
                    $fixer->emit_set_key($var, $key, $fixer->emit_value($default)) .
                "}";
            }
            $perl;
        });
    });
}

=head1 NAME

Catmandu::Fix::lookup_in_store - change the value of a HASH key or ARRAY index by looking up it's value in a store

=head1 SYNOPSIS

   lookup_in_store('foo.bar', 'MongoDB', bag: 'bars', database_name: 'lookups');
   # using the default bag and a default value
   lookup_in_store('foo.bar', 'store_name', default: 'default value');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;

