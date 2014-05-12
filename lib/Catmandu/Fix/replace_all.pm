package Catmandu::Fix::replace_all;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path    => (fix_arg => 1);
has search  => (fix_arg => 1);
has replace => (fix_arg => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;
    my $search = $self->search;
    my $replace = $self->replace;

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            "if (is_value(${var})) {"
                ."utf8::upgrade(${var});"
                ."${var} =~ s{$search}{$replace}g;"
                ."}";
        });
    });
}

=head1 NAME

Catmandu::Fix::replace_all - search and replace using regex expressions

=head1 SYNOPSIS

   # Extract a substring out of the value of a field
   replace_all('year','\^','0');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
