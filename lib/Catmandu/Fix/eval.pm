package Catmandu::Fix::eval;

use Catmandu::Sane;

our $VERSION = '1.10';

use Catmandu::Fix;
use Catmandu::Util qw(:is data_at);
use Moo;

with 'Catmandu::Fix::Inlineable';

has path => (is => 'ro' , required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path) = @_;
    $orig->($class, path => $path);
};

sub fix {
    my ($self, $data) = @_;
    my $code = data_at($self->path, $data);
    return $data unless $code && (is_string($code) || is_array_ref($code));
    $code = [ $code ] unless is_array_ref($code);
    my $fixer = Catmandu::Fix->new(fixes => $code);
    return $data unless $fixer;
    $fixer->fix($data);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::eval - evaluate stored in a variable

=head1 SYNOPSIS

   # fixes => 'add_field(foo,bar)'
   eval(fixes) # foo => bar

   # fixer => ['add_field(foo,bar)','upcase(foo)']
   eval(fixes) # foo => BAR

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
