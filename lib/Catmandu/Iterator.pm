package Catmandu::Iterator;
use Catmandu::Sane;
use parent qw(Catmandu::Iterable);
use Catmandu::Util qw(quack);

sub new {
    my ($class, $arg) = @_;

    my $self;

    if (ref($arg) eq 'CODE') {
        $self = $arg;
    } elsif (ref($arg) eq 'ARRAY') {
        $self = sub { my $sub = $_[0]; for my $obj (@$arg) { $sub->($obj) }; scalar(@$arg) };
    } elsif (quack $arg, 'next') {
        $self = sub { my $sub = $_[0]; my $n = 0; while (my $obj = $arg->next) { $sub->($obj); $n++ }; $n };
    } elsif (quack $arg, 'each') {
        $self = sub { my $sub = $_[0]; $arg->each($sub) };
    } else {
        confess "invalid arg";
    }

    bless $self, ref($class) || $class;
}

sub each {
    $_[0]->($_[1]);
}

1;
