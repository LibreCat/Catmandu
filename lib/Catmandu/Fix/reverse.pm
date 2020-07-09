package Catmandu::Fix::reverse;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path => (fix_arg => 1);

sub _build_fixer {
    my ($self) = @_;
    as_path($self->path)->updater(
        if_array_ref => sub {
            [reverse(@{$_[0]})];
        },
        if_string => sub {
            scalar(reverse($_[0]));
        },
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::reverse - reverse a string or an array

=head1 SYNOPSIS

   # {author => "tom jones"}
   reverse(author)
   # {author => "senoj mot"}

   # {numbers => [1,14,2]}
   reverse(numbers)
   # {numbers => [2,14,1]}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
