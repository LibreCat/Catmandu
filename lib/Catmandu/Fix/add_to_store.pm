package Catmandu::Fix::add_to_store;

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

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $val_var = shift;
            "if (is_hash_ref(${val_var})) {" .
                "${bag_var}->add(${val_var});" .
            "}";
        });
    });
}

=head1 NAME

Catmandu::Fix::add_to_store - add matching values to a store as a side effect

=head1 SYNOPSIS

   add_to_store('authors.*', 'MongoDB', '-bag', 'authors', '-database_name', 'catalog');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;

