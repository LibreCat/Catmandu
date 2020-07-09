package Catmandu::Fix::flatten;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use Catmandu::Util qw(is_array_ref);
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Builder';

sub _build_fixer {
    my ($self) = @_;
    as_path($self->path)->updater(
        if_array_ref => sub {
            my $data = $_[0];
            $data = [map {is_array_ref($_) ? @$_ : $_} @$data]
                while grep {is_array_ref($_)} @$data;
            $data;
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::flatten - flatten a nested array field

=head1 SYNOPSIS

   # {deep => [1, [2, 3], 4, [5, [6, 7]]]}
   flatten(deep)
   # {deep => [1, 2, 3, 4, 5, 6, 7]}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
