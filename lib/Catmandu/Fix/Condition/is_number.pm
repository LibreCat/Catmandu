package Catmandu::Fix::Condition::is_number;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util qw(is_number);
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Condition::Builder::Simple';

sub _build_value_tester {
    \&is_number;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::is_string - only execute fixes if all path values are numbers

=head1 SYNOPSIS

   if is_number(data.*)
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
