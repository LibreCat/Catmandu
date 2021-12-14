package Catmandu::Fix::eval;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Moo;
use List::Util qw(all);
use Catmandu::Fix;
use Catmandu::Util qw(is_string is_array_ref);
use Catmandu::Util::Path qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Builder';

sub _build_fixer {
    my ($self) = @_;
    my $getter = as_path($self->path)->getter;
    sub {
        my $data = $_[0];
        for my $fixes (@{$getter->($data)}) {
            $fixes = [$fixes] unless is_array_ref($fixes);
            next              unless @$fixes && all {is_string($_)} @$fixes;
            my $fixer = Catmandu::Fix->new(fixes => $fixes);
            $data = $fixer->fix($data);
        }
        $data;
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::eval - eval and execute fixes defined in a field

=head1 SYNOPSIS

    # {fixes => 'add_field(foo,bar)'}
    eval(fixes)
    # {fixes => 'add_field(foo,bar)', foo => 'bar'}

    # {fixes => ['add_field(foo,bar)','upcase(foo)'], foo => 'bar'}
    eval(fixes)
    # {fixes => ['add_field(foo,bar)','upcase(foo)'], foo => 'BAR'}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
