package Catmandu::Fix::Bind::each;

our $VERSION = '1.07';

use strict;
use warnings;

use Catmandu::Sane;
use Moo;

use Catmandu::Util;
use Catmandu::Fix::Has;
use Carp;

with 'Catmandu::Fix::Bind','Catmandu::Fix::Bind::Group';

has path      => (fix_opt => 1);
has var       => (fix_opt => 1);

has _root_ => (is => 'rw');

sub unit {
    my ($self, $data) = @_;

    croak "need a path" unless $self->path;
    croak "need a var"  unless $self->var;

    $self->_root_($data);

    if ($self->path eq "." || ! length($self->path)) {
        return $data;
    }
    else {
        return Catmandu::Util::data_at($self->path, $data);
    }
}

sub bind {
    my ($self, $data, $code) = @_;

    if (!Catmandu::Util::is_hash_ref($data)) {
        $code->($data);
    }
    else {
        for my $key (sort keys %{$data}) {
            my $value = $data->{$key};

            my $scope = $self->_root_;

            $scope->{$self->var} = {
                    'key'   => $key,
                    'value' => $value
            };

            $code->($scope);

            delete $scope->{$self->var}
        }
    }

    return $data;
}

1;
__END__

=pod

=head1 NAME

Catmandu::Fix::Bind::each - a binder that executes fixes for every (key, value) pair in a hash

=head1 SYNOPSIS

    # Create a hash:
    # demo:
    #   nl: 'Tuin der lusten'
    #   en: 'The Garden of Earthly Delights'

    # Create a list of all the titles, without the language tags.
    do each(path: demo, var: t)
        copy_field(t.value, titles.$append)
    end

    # This will result in:
    # demo:
    #   nl: 'Tuin der lusten'
    #   en: 'The Garden of Earthly Delights'
    # titles:
    #   - 'Tuin der lusten'
    #   - 'The Garden of Earthly Delights'

=head1 DESCRIPTION

The each binder will iterate over a hash and return a (key, value)
pair (see the Perl L<each|http://perldoc.perl.org/functions/each.html> function
for the inspiration for this bind) and execute all fixes for each pair.

The bind always returns a C<var.key> and C<var.value> pair which can be used
in the fixes.

=head1 CONFIGURATION

=head2 path

The path to a hash in the data.

=head2 var

The temporary field that will be created in the root of the record
containing a C<key> and C<value> field containing the I<key> and
I<value> of the iterated data.

=head1 AUTHOR

Pieter De Praetere, C<< pieter.de.praetere at helptux.be >>

=head1 SEE ALSO

L<Catmandu::Fix::Bind::list>
L<Catmandu::Fix::Bind>

=cut
