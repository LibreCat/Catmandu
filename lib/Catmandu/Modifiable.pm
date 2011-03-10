package Catmandu::Modifiable;
use Catmandu::Sane;
use Catmandu::Util qw(get_subroutine add_subroutine);

sub before {
    my ($pkg, $sym, $sub) = @_;
    my $old = get_subroutine($pkg, $sym, parents => 1)
        or confess "Can't wrap undefined subroutine $sym";

    no warnings 'redefine';
    add_subroutine($pkg, $sym, sub {
        $sub->(@_);
        $old->(@_);
    });
}

sub after {
    my ($pkg, $sym, $sub) = @_;
    my $old = get_subroutine($pkg, $sym, parents => 1)
        or confess "Can't wrap undefined subroutine $sym";

    no warnings 'redefine';
    add_subroutine($pkg, $sym, sub {
        my @val = $old->(@_);
        $sub->(@_);
        @val;
    });
}

sub around {
    my ($pkg, $sym, $sub) = @_;
    my $old = get_subroutine($pkg, $sym, parents => 1)
        or confess "Can't wrap undefined subroutine $sym";

    no warnings 'redefine';
    add_subroutine($pkg, $sym, sub {
        $sub->($old, @_);
    });
}

no Catmandu::Util;
1;
