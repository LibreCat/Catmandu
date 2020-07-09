package Catmandu::Fix::Condition::is_true;

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
            is_bool($_[0]) && $_[0];
        };
    }
    else {
        sub {
            my $val = $_[0];
            (is_bool($val) && $val)
                || (is_number($val) && $val == 1)
                || (is_string($val) && $val eq 'true');
        };
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::is_true - only execute fixes if all path values are the boolean true, 1 or "true"

=head1 SYNOPSIS

    if is_true(data.*.has_error)
        ...
    end

    # strict only matches a real bool, not 1 or "1" or "true"
    if is_true(data.*.has_error, strict: 1)
        ...
    end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
