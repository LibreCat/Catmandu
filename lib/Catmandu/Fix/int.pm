package Catmandu::Fix::int;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util qw(is_string is_array_ref is_hash_ref);
use Catmandu::Util::Path qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Builder';

sub _build_fixer {
    my ($self) = @_;

    as_path($self->path)->updater(
        sub {
            my $val = $_[0];
            if (is_string($val) and my ($num) = $val =~ /([+-]?[0-9]+)/) {
                $num + 0;
            }
            elsif (is_array_ref($val)) {
                scalar(@$val);
            }
            elsif (is_hash_ref($val)) {
                scalar(keys %$val);
            }
            else {
                0;
            }
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::int - convert a value to an integer

=head1 SYNOPSIS

    # year => "2016"
    int(year)
    # year => 2016

    # foo => "bar-123baz"
    int(foo)
    # foo => -123

    # foo => ""
    int(foo)
    # foo => 0

    # foo => "abc"
    int(foo)
    # foo => 0

    # foo => []
    int(foo)
    # foo => 0

    # foo => ["a", "b", "c"]
    int(foo)
    # foo => 3

    # foo => {a => "b", c => "d"}
    int(foo)
    # foo => 2

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
