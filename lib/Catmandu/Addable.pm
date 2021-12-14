package Catmandu::Addable;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Catmandu::Util qw(:is :check);
use Moo::Role;
use namespace::clean;

with 'Catmandu::Fixable';

requires 'add';

has autocommit => (is => 'ro', default => sub {0});
has _commit    => (is => 'rw', default => sub {0});

around add => sub {
    my ($orig, $self, $data) = @_;
    return unless defined $data;
    $data = $self->_fixer->fix($data) if $self->_fixer;
    $orig->($self, $data)             if defined $data;
    $data;
};

around commit => sub {
    my ($orig, $self) = @_;
    my (@res) = $orig->($self);
    $self->_commit(1);
    @res;
};

sub add_many {
    my ($self, $many) = @_;

    if (is_hash_ref($many)) {
        $self->add($many);
        return 1;
    }

    if (is_array_ref($many)) {
        $self->add($_) for @$many;
        return scalar @$many;
    }

    if (is_invocant($many)) {
        $many = check_able($many, 'generator')->generator;
    }

    check_code_ref($many);

    my $data;
    my $n = 0;
    while (defined($data = $many->())) {
        $self->add($data);
        $n++;
    }
    $n;
}

sub commit { }

sub DESTROY {
    my ($self) = shift;
    $self->commit if $self->autocommit && !$self->_commit;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Addable - Base class for all Catmandu modules need to implement add

=head1 SYNOPSIS

    package My::Adder;

    use Moo;
    use Data::Dumper;
  
    with 'Catmandu::Addable';

    sub add {
        my ($self,$object) = @_;

        print "So you want to add:\n";
        print Dumper($object);

        1;
    }

    sub commit {
        my $self = shift;

        print "And now you are done?\n";
    }

    package main;

    my $adder = My::Adder->new(fix => ['upcase(foo)']);

    # prints foo => BAR
    $adder->add({ foo => 'bar' });
    
    # prints:
    #  foo => BAR
    #  foo => BAR
    $adder->add_many([ { foo => 'bar' } , { foo => 'bar' }]);

    # prints a commit statement
    $adder->commit;

=head1 OPTIONS

=over

=item autocommit

Autocommit when the exporter gets out of scope. Default 0.

=back

=head1 METHODS

=head2 add($hash)

Receives a Perl hash and should return true or false.

=head2 commit

This method is usually called at the end of many add or add_many operations.

=head1 INHERIT

If you provide an 'add' method, then automatically your package gets a add_many
method, plus a fix attribute which transforms all Perl hashes provided to the
add method.

=head1 SEE ALSO

L<Catmandu::Fixable>, L<Catmandu::Exporter> , L<Catmandu::Store>

=cut
