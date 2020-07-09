package Catmandu::Fix::Condition::is_string;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util qw(is_number is_value);
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Condition::Builder::Simple';

sub _build_value_tester {
    sub {
        !is_number($_[0]) && is_value($_[0]);
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::is_string - only execute fixes if all path values are strings

=head1 SYNOPSIS

   if is_string(data.*)
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
