package Catmandu::Fix::env;

use Catmandu::Sane;

our $VERSION = '1.2008';

use Moo;
use Catmandu::Util::Path qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path  => (fix_arg => 1);
has value => (fix_arg => 1, default => sub {undef});

sub _build_fixer {
    my ($self) = @_;
    my $v = $ENV{$self->value};
    as_path($self->path)->creator($v);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::env - add or change the value of a HASH key or ARRAY index via
environment variables

=head1 DESCRIPTION

The C<env> fix behaves the same way as the <add_field> fix. Intermediate structures
are created if they are missing.

=head1 SYNOPSIS

    # on the command line
    $ ENV_MYVAL=bar catmandu convert Null to YAML --fix "env(foo, ENV_MYVAL)"
    # output
    ---
    foo: bar
    ...

    # Add a new field 'foo' with value from ENV_MYVAL
    env(foo, ENV_MYVAL)

    # Create a deeply nested key with value from ENV_MYVAL
    add_field(my.deep.nested.key, ENV_MYVAL)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
