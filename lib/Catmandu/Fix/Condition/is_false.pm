package Catmandu::Fix::Condition::is_false;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util qw(is_number is_string is_bool);
use namespace::clean;
use Catmandu::Fix::Has;

has path   => (fix_arg => 1);
has strict => (fix_opt => 1);

with 'Catmandu::Fix::Condition::Builder::Simple';

sub _build_value_tester {
    my ($self) = @_;
    if ($self->strict) {
        sub {
            is_bool($_[0]) && !$_[0];
        };
    }
    else {
        sub {
            my $val = $_[0];
            (is_bool($val) && !$val)
                || (is_number($val) && $val == 0)
                || (is_string($val) && $val eq 'false');
        };
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::is_false - only execute fixes if all path values are the boolean false, 0 or "false"

=head1 SYNOPSIS

    if is_false(data.*.has_error)
        ...
    end

    # strict only matches a real bool, not 0 or "0" or "false"
    if is_false(data.*.has_error, strict: 1)
        ...
    end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
