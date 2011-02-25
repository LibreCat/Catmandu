package Catmandu::Fixer;
# VERSION
use Moose;
use Catmandu::Util qw(load_class unquote quoted trim);
use Catmandu::Iterator;
use JSON::Path;
use Clone ();

sub load_fix_arg {
    my $arg = shift;

    if (quoted($arg)) {
        return unquote($arg);
    } elsif ($arg =~ /^\d+$/) {
        return $arg;
    } elsif ($arg =~ /^\$.+/) {
        return JSON::Path->new($arg);
    } elsif ($arg eq '$') {
        return undef;
    } else {
        my $val = eval $arg;
        confess "Whoops : $@" if $@;
        return $val;
    }

    confess "Invalid argument";
}

sub load_fix {
    my $fix = shift;

    return if not $fix;
    return $fix if blessed $fix and $fix->isa('Catmandu::Fixer::Fix');
    return if ref $fix;

    if (my ($name, $args) = ($fix =~ /^\s*(\w+)\((.*)\)\s*$/)) {
        my $class = load_class $name, 'Catmandu::Fixer::Fix';
        my @args  = map { load_fix_arg trim($_) } split /,/, $args;
        return $class->new(@args);
    }
    return;
}

has fixes => (
    is => 'ro',
    isa => 'ArrayRef[Catmandu::Fixer::Fix]',
    required => 1,
    default => sub { [] },
);

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

no Moose;
no Catmandu::Util;

1;

