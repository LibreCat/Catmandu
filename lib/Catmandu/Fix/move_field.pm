package Catmandu::Fix::move_field;

use Catmandu::Sane;
use Moo;

with 'Catmandu::Fix::Base';

has old_path => (is => 'ro', required => 1);
has new_path => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $old_path, $new_path) = @_;
    $orig->($class, old_path => $old_path,
                    new_path => $new_path);
};

sub emit {
    my ($self, $fixer) = @_;
    my $old_path = $fixer->split_path($self->old_path);
    my $old_key = pop @$old_path;
    my $new_path = $fixer->split_path($self->new_path);

    $fixer->emit_walk_path($fixer->var, $old_path, sub {
        my $var = shift;
        $fixer->emit_delete_key($var, $old_key, sub {
            my $vals = shift;
            $fixer->emit_create_path($fixer->var, $new_path, sub {
                my $var = shift;
                "if (\@{${vals}}) {".
                    "${var} = shift(\@{${vals}});".
                "}";
            });
        });
    });
}

=head1 NAME

Catmandu::Fix::move_field - move a field to another place in the data structure

=head1 SYNOPSIS

   # Move 'foo.bar' to 'bar.foo'
   move_field('foo.bar','bar.foo');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
