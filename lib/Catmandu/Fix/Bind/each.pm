package Catmandu::Fix::Bind::each;

our $VERSION = '1.2013';

use strict;
use warnings;

use Catmandu::Sane;
use Moo;

use Catmandu::Util;
use Catmandu::Fix::Has;
use Carp;

with 'Catmandu::Fix::Bind', 'Catmandu::Fix::Bind::Group';

has path => (fix_opt => 1);
has var  => (fix_opt => 1);

has _root_ => (is => 'rw');

sub unit {
    my ($self, $data) = @_;

    $self->_root_($data);

    if ($self->path && $self->path ne '.') {
        return Catmandu::Util::data_at($self->path, $data);
    }
    else {
        return $data;
    }
}

sub bind {
    my ($self, $data, $code) = @_;

    if (!Catmandu::Util::is_hash_ref($data)) {
        $code->($data);
    }
    else {
        my @keys = sort keys %{$data};
        for my $key (@keys) {
            my $value = $data->{$key};
            my $scope;

            if ($self->var) {
                $scope = $self->_root_;

                $scope->{$self->var} = {'key' => $key, 'value' => $value};
            }
            else {
                $scope            = $data;
                $scope->{'key'}   = $key;
                $scope->{'value'} = $value;
            }

            $code->($scope);

            if ($self->var) {

                # Key and values can be updated
                if (my $mkey = $scope->{$self->var}->{key}) {
                    $data->{$mkey} = $scope->{$self->var}->{value};
                    if ($mkey ne $key) {
                        delete $data->{$key};
                    }
                }

                delete $scope->{$self->var};
            }
            else {
                if (my $mkey = $scope->{key}) {
                    $data->{$mkey} = $scope->{value};
                    if ($mkey ne $key) {
                        delete $data->{$key};
                    }
                }

                delete $scope->{'key'};
                delete $scope->{'value'};
            }
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

    # Upcase every key in the root hash
    # foo: bar
    # test: 1234
    do each(path:., var: t)
       upcase(t.key)
    end

    # This will result in
    # FOO: bar
    # TEST: 1234

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
