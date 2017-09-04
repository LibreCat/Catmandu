package Catmandu::Fix::retain_field;

use Catmandu::Sane;

our $VERSION = '1.0603';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path => (fix_arg => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key  = pop @$path;

    $fixer->emit_walk_path(
        $fixer->var,
        $path,
        sub {
            my $var = shift;
            $fixer->emit_retain_key($var, $key);
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::retain_field - delete everything from a field except 

=head1 DEPRECIATION NOTICE

This fix is deprecated, Please use L<Catmandu::Fix::retain> instead.

=head1 SYNOPSIS

   # Delete every key from foo except bar
   retain_field(foo.bar)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
