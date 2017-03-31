package Catmandu::Fix::set_hash;

use Catmandu::Sane;

our $VERSION = '1.05';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path => (fix_arg => 1);
has values => (fix_arg => 'collect', default => sub {[]});

sub emit {
    my ($self, $fixer) = @_;
    my $path   = $fixer->split_path($self->path);
    my $key    = pop @$path;
    my $values = $self->values;

    $fixer->emit_walk_path(
        $fixer->var,
        $path,
        sub {
            my $var = shift;
            $fixer->emit_set_key($var, $key,
                "{" . join(',', map {$fixer->emit_value($_)} @$values) . "}");
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::set_hash - add or change the value of a HASH key or ARRAY index to a hash

=head1 DESCRIPTION

Contrary to C<add_field>, this will not create the intermediate structures
if they are missing.

=head1 SYNOPSIS

   # Change the value of 'foo' to an empty hash
   set_hash(foo)
   # Or a hash with initial contents
   set_hash(a: b, c: d)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
