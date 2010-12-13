package Catmandu::Fixer;

use namespace::autoclean;
use Moose;
use Catmandu::Iterator;
use File::Slurp qw(slurp);
use Catmandu::Util qw(load_class);
use Clone ();

has fixes => (
    is => 'ro',
    isa => 'ArrayRef[Catmandu::Fixer::Fix]',
    required => 1,
    default => sub { [] },
);

sub load_fix {
    my $fix = pop;

    return if not $fix;
    return $fix if blessed $fix and $fix->isa('Catmandu::Fixer::Fix');
    return if ref $fix;

    if ($fix =~ /^\s*(\w+)\((.*)\)\s*$/) {
        my $name = $1;
        my @args = split /\s*,\s*/, $2;

        return load_class($name, 'Catmandu::Fixer::Fix')->new(@args);
    }

    return;
}

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    { fixes => [ grep { $_ } map { load_fix $_ } @args ] };
};

sub fix {
    my ($self, $obj) = @_;

    my $fixes = $self->fixes;

    if (ref $obj eq 'ARRAY') {
        return [ map {
            my $clone = Clone::clone $_;
            for my $fix (@$fixes) {
                $fix->apply_fix($clone);
            }
            $clone;
        } @$obj ];
    }

    if (ref $obj eq 'HASH') {
        $obj = Clone::clone $obj;
        for my $fix (@$fixes) {
            $fix->apply_fix($obj);
        }
        return $obj;
    }

    if (blessed $obj and $obj->can('each')) {
        return Catmandu::Iterator->new(sub {
            my $sub = $_[0];
            $obj->each(sub {
                my $clone = Clone::clone $_[0];
                for my $fix (@$fixes) {
                    $fix->apply_fix($clone);
                }
                $sub->($clone);
            });
        });
    }

    confess "Can't fix object";
}

__PACKAGE__->meta->make_immutable;

1;

