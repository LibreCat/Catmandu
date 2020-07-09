package Catmandu::Fix::substring;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Catmandu::Util qw(as_utf8);
use Catmandu::Util::Path qw(as_path);
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);
has args => (fix_arg => 'collect');

with 'Catmandu::Fix::Builder';

sub _build_fixer {
    my ($self) = @_;
    my $args = $self->args;
    my $cb;

    if (@$args == 1) {
        $cb = sub {
            my $val = $_[0];
            my $new_val;
            eval {
                no warnings 'substr';
                $new_val = substr(as_utf8($val), $args->[0]);
            };
            return $new_val if defined $new_val;
            return undef, 1, 0;
        };
    }
    elsif (@$args == 2) {
        $cb = sub {
            my $val = $_[0];
            my $new_val;
            eval {
                no warnings 'substr';
                $new_val = substr(as_utf8($val), $args->[0], $args->[1]);
            };
            return $new_val if defined $new_val;
            return undef, 1, 0;
        };
    }
    else {
        $cb = sub {
            my $val     = $_[0];
            my $new_val = as_utf8($val);
            eval {
                no warnings 'substr';
                substr($new_val, $args->[0], $args->[1]) = $args->[2];
            } // return undef, 1, 0;
            $new_val;
        };
    }

    as_path($self->path)->updater(if_value => $cb);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::substring - extract a substring out of the value of a field

=head1 SYNOPSIS

   # Extract a substring out of the value of a field
   # - Extact from 'initials' the characters at offset 0 (first character) with a length 3
   substring(initials, 0, 3)

=head1 SEE ALSO

L<Catmandu::Fix>, substr

=cut
