package Catmandu::Fix::lookup_in_store;

use Catmandu::Sane;
use Catmandu;
use Moo;

with 'Catmandu::Fix::Base';

has path       => (is => 'ro', required => 1);
has store_name => (is => 'ro', required => 1);
has opts       => (is => 'ro');
has bag        => (is => 'ro', lazy => 1, builder => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $store_name, %opts) = @_;
    $orig->($class,
        path => $path,
        store_name => $store_name,
        opts => \%opts,
    );
};

sub _build_bag {
    my ($self) = @_;
    my %opts = %{$self->opts};
    my $bag_name = delete $opts{'-bag'};
    delete $opts{'-delete'};
    delete $opts{'-default'};
    for my $key (keys %opts) {
        my $val = delete $opts{$key};
        $key =~ s/^-//;
        $key =~ s/-/_/g;
        $opts{$key} = $val;
    }
    Catmandu->store($self->store_name, %opts)->bag($bag_name);
}

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;
    my $bag_var = $fixer->capture($self->bag);
    my $delete = $self->opts->{'-delete'};
    my $default = $self->opts->{'-default'};

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $val_var = shift;
            my $bag_val_var = $fixer->generate_var;
            my $perl = "if (is_value(${val_var}) && defined(my ${bag_val_var} = ${bag_var}->get(${val_var}))) {" .
                "${val_var} = ${bag_val_var};" .
            "}";
            if ($delete) {
                $perl .= "else {" .
                    $fixer->emit_delete_key($var, $key) .
                "}";
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

   lookup_in_store('foo.bar', 'MongoDB', '-bag', 'bars', '-database_name', 'lookups');
   # using the default bag and a default value
   lookup_in_store('foo.bar', 'store_name', '-default', 'default value');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;

