package Catmandu::Fix::sum;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Catmandu::Util qw(is_number);
use Catmandu::Util::Path qw(as_path);
use List::Util qw(all sum);
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path => (fix_arg => 1);

sub _build_fixer {
    my ($self) = @_;
    as_path($self->path)->updater(
        if_array_ref => sub {
            my $val = $_[0];
            return undef, 1 unless all {is_number($_)} @$val;
            sum(@$val) // 0;
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::sum - replace the value of an array field with the sum of its elements

=head1 SYNOPSIS

   # e.g. numbers => [2, 3]
   sum(numbers)
   # numbers => 5

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
