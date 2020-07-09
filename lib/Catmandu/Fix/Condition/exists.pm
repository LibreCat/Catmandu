package Catmandu::Fix::Condition::exists;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Condition::Builder';

sub _build_tester {
    my ($self) = @_;
    my $getter = as_path($self->path)->getter;
    sub {
        @{$getter->($_[0])} ? 1 : 0;
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::exists - only execute fixes if the path exists

=head1 SYNOPSIS

   # uppercase the value of field 'foo' if the field 'oogly' exists
   if exists(oogly)
     upcase(foo) # foo => 'BAR'
   end
   # inverted
   unless exists(oogly)
     upcase(foo) # foo => 'bar'
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
