package Catmandu::Iterator;
use Catmandu::Sane;
use parent qw(Catmandu::Iterable);

sub new {
    my ($self, $arg) = @_;

    my $each;

    if (ref($arg) eq 'CODE') {
        $each = $arg;
    } elsif (ref($arg) eq 'ARRAY') {
        $each = sub { my $sub = $_[0]; $sub->($_) for @$arg; scalar(@$arg); };
    } elsif (quack $arg, 'each') {
        $each = sub { my $sub = $_[0]; $arg->each($sub) };
    } else {
        confess "invalid arg";
    }

    bless $each, ref($self) || $self;
}

sub each {
    $_[0]->($_[1]);
}

1;
