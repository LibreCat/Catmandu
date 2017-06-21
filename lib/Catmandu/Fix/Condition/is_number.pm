package Catmandu::Fix::Condition::is_number;

use Catmandu::Sane;

our $VERSION = '1.0601';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var) = @_;
    "is_number(${var})";
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
