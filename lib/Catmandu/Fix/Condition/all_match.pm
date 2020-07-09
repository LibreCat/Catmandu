package Catmandu::Fix::Condition::all_match;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util qw(is_value);
use Catmandu::Util::Regex qw(as_regex);
use namespace::clean;
use Catmandu::Fix::Has;

has path    => (fix_arg => 1);
has pattern => (fix_arg => 1);

with 'Catmandu::Fix::Condition::Builder::Simple';

sub _build_value_tester {
    my ($self) = @_;
    my $re = as_regex($self->pattern);
    sub {
        my $v = $_[0];
        is_value($v) && $v =~ $re;
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::all_match - only execute fixes if all path values match the given regex

=head1 SYNOPSIS

   # uppercase the value of field 'foo' if all members of 'oogly' have the value 'doogly'
   if all_match(oogly.*, "doogly")
     upcase(foo) # foo => 'BAR'
   end

   # case insensitive search for 'doogly' in all 'oogly'
   if all_match(oogly.*, "(?i)doogly")
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
