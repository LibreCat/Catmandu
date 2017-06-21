package Catmandu::Fix::Condition::is_object;

use Catmandu::Sane;

our $VERSION = '1.0601';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var) = @_;
    "is_hash_ref(${var})";
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
