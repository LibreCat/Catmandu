package Catmandu::Fix::Condition::is_array;

use Catmandu::Sane;

our $VERSION = '1.06';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var) = @_;
    "is_array_ref(${var})";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::is_array - only execute fixes if all path values are arrays

=head1 SYNOPSIS

   if is_array(data.*.list)
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
