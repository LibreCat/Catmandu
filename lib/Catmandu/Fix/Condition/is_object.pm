package Catmandu::Fix::Condition::is_object;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util qw(is_hash_ref);
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Condition::Builder::Simple';

sub _build_value_tester {
    \&is_hash_ref;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::is_object - only execute fixes if all path values are objects (unordered sets of name-value pairs)

=head1 SYNOPSIS

   if is_object(data.*)
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
