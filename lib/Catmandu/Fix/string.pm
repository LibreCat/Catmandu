package Catmandu::Fix::string;

use Catmandu::Sane;

our $VERSION = '1.2013';

use List::Util qw(all);
use Catmandu::Util qw(is_string is_value is_array_ref is_hash_ref);
use Catmandu::Util::Path qw(as_path);
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path => (fix_arg => 1);

sub _build_fixer {
    my ($self) = @_;

    as_path($self->path)->updater(
        sub {
            my $val = $_[0];
            if (is_string($val)) {
                "${val}";
            }
            elsif (is_array_ref($val) && all {is_value($_)} @$val) {
                join('', @$val);
            }
            elsif (is_hash_ref($val) && all {is_value($_)} values %$val) {
                join('', map {$val->{$_}} sort keys %$val);
            }
            else {
                '';
            }
        }
    );

}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::string - convert a value to a string

=head1 SYNOPSIS

    # year => 2016
    string(year)
    # year => "2016"

    # foo => ["a", "b", "c"]
    string(foo)
    # foo => "abc"

    # foo => ["a", {b => "c"}, "d"]
    string(foo)
    # foo => ""
    
    # foo => {2 => "b", 1 => "a"}
    string(foo)
    # foo => "ab"

    # foo => {a => ["b"]}
    string(foo)
    # foo => ""

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
