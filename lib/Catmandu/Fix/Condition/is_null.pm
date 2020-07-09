package Catmandu::Fix::Condition::is_null;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Condition::Builder::Simple';

sub _build_value_tester {
    sub {
        defined($_[0]) ? 0 : 1;
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::is_null - only execute fixes if all path values are null

=head1 SYNOPSIS

   if is_null(data.*)
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
