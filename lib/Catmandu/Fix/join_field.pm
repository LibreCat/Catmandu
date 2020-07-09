package Catmandu::Fix::join_field;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use Catmandu::Util qw(is_value);
use namespace::clean;
use Catmandu::Fix::Has;

has path      => (fix_arg => 1);
has join_char => (fix_arg => 1, default => sub {''});

with 'Catmandu::Fix::Builder';

sub _build_fixer {
    my ($self) = @_;
    my $join_char = $self->join_char;
    as_path($self->path)->updater(
        if_array_ref => sub {
            join $join_char, grep {is_value($_)} @{$_[0]};
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::join_field - join the ARRAY values of a field into a string

=head1 SYNOPSIS

   # Join the array values of a field into a string. E.g. foo => [1,2,3]
   join_field(foo, /) # foo => "1/2/3"

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
