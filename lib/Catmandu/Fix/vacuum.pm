package Catmandu::Fix::vacuum;

use Catmandu::Sane;

our $VERSION = '1.0604';

use Catmandu::Util qw(is_value is_hash_ref is_array_ref);
use Scalar::Util qw(refaddr);
use Moo;
use namespace::clean;

with 'Catmandu::Fix::Inlineable';

sub _visit {
    my ($self, $v) = @_;
    (is_hash_ref($v) && %$v) || (is_array_ref($v) && @$v);
}

sub _empty {
    my ($self, $v) = @_;
    !defined($v)
        || (is_value($v)     && $v !~ /\S/)
        || (is_hash_ref($v)  && !%$v)
        || (is_array_ref($v) && !@$v);
}

sub fix {
    my ($self, $data) = @_;

    return $data unless $self->_visit($data);

    my @stack = ($data);
    my %seen;

    while (@stack) {
        my $d  = pop @stack;
        my $id = refaddr($d);

        if ($seen{$id}) {
            if (is_hash_ref($d)) {
                for my $k (keys %$d) {
                    delete $d->{$k} if $self->_empty($d->{$k});
                }
            }
            elsif (is_array_ref($d)) {
                my @vals = grep {!$self->_empty($_)} @$d;
                splice(@$d, 0, @$d, @vals);
            }
        }
        else {
            $seen{$id} = 1;
            push @stack, $d;

            if (is_hash_ref($d)) {
                for my $k (keys %$d) {
                    my $v = $d->{$k};
                    if ($self->_empty($v)) {
                        delete $d->{$k};
                    }
                    elsif ($self->_visit($v)) {
                        push @stack, $v;
                    }
                }
            }
            elsif (is_array_ref($d)) {
                my @vals;
                for my $v (@$d) {
                    next if $self->_empty($v);
                    push @vals, $v;
                    push @stack, $v if $self->_visit($v);
                }
                splice @$d, 0, @$d, @vals;
            }
        }
    }

    $data;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::vacuum - delete all empty fields from your data

=head1 SYNOPSIS

   # Delete all the empty fields
   #
   # input:
   #
   # foo: ''
   # bar: []
   # relations: {}
   # test: 123
   #
   vacuum()
   
   # output:
   #
   # test: 123
   #

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
