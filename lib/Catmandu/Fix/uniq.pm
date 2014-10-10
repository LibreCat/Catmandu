package Catmandu::Fix::uniq;
use Catmandu::Sane;
use Moo;
use List::MoreUtils;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path  => (fix_arg => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;

    $fixer->emit_walk_path($fixer->var,$path,sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            "${var} = [List::MoreUtils::uniq(\@{ ${var} })] if is_array_ref(${var});";
        });
    });
}

=head1 NAME

Catmandu::Fix::uniq - remove duplicate from a list

=head1 SYNOPSIS

   #["RE","RE"] becomes ["RE"]
   uniq('faculty');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
