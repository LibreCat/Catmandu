package Catmandu::Iterable;

use Catmandu::Sane;
use Data::Compare ();
require Catmandu::Iterator;
use Role::Tiny;

requires 'generator';

sub to_array {
    my ($self) = @_;
    my $next = $self->generator;
    my @a;
    my $data;
    while ($data = $next->()) {
        push @a, $data;
    }
    \@a;
}

sub count {
    my ($self) = @_;
    my $next = $self->generator;
    my $n = 0;
    while ($next->()) {
        $n++;
    }
    $n;
}

sub slice {
    my ($self, $start, $total) = @_;
    $start //= 0;
    Catmandu::Iterator->new(sub {
        sub {
            if (defined $total) {
                $total || return;
            }
            state $next = $self->generator;
            state $data;
            while ($data = $next->()) {
                if ($start > 0) {
                    $start--;
                    next;
                }
                if (defined $total) {
                    $total--;
                }
                return $data;
            }
            return;
        };
    });
}

sub each {
    my ($self, $sub) = @_;
    my $next = $self->generator;
    my $n = 0;
    my $data;
    while ($data = $next->()) {
        $sub->($data);
        $n++;
    }
    $n;
}

sub tap {
    my ($self, $sub) = @_;
    Catmandu::Iterator->new(sub {
        sub {
            state $next = $self->generator;
            state $data;
            if ($data = $next->()) {
                $sub->($data);
                return $data;
            }
            return;
        };
    });
}

sub any {
    my ($self, $sub) = @_;
    my $next = $self->generator;
    my $data;
    while ($data = $next->()) {
        $sub->($data) && return 1;
    }
    return 0;
}

sub many {
    my ($self, $sub) = @_;
    my $next = $self->generator;
    my $n = 0;
    my $data;
    while ($data = $next->()) {
        $sub->($data) && ++$n > 1 && return 1;
    }
    return 0;
}

sub all {
    my ($self, $sub) = @_;
    my $next = $self->generator;
    my $data;
    while ($data = $next->()) {
        $sub->($data) || return 0;
    }
    return 1;
}

sub map {
    my ($self, $sub) = @_;
    Catmandu::Iterator->new(sub {
        sub {
            state $next = $self->generator;
            $sub->($next->() || return);
        };
    });
}

sub reduce {
    my $self = shift;
    my $sub  = pop;
    my $memo = pop;
    my $next = $self->generator;
    my $data;
    while ($data = $next->()) {
        if (defined $memo) {
            $memo = $sub->($memo, $data);
        } else {
            $memo = $data;
        }
    }
    $memo;
}

sub first {
    $_[0]->generator->();
}

sub rest {
    $_[0]->slice(1);
}

sub take {
    my ($self, $n) = @_;
    Catmandu::Iterator->new(sub {
        sub {
            --$n > 0 || return;
            state $next = $self->generator;
            $next->();
        };
    });
}

sub detect {
    my ($self, $sub) = @_;
    my $next = $self->generator;
    my $data;
    while ($data = $next->()) {
        $sub->($data) && return $data;
    }
    return;
}

sub select {
    my ($self, $sub) = @_;
    Catmandu::Iterator->new(sub {
        sub {
            state $next = $self->generator;
            state $data;
            while ($data = $next->()) {
                $sub->($data) && return $data;
            }
            return;
        };
    });
}

sub reject {
    my ($self, $sub) = @_;
    Catmandu::Iterator->new(sub {
        sub {
            state $next = $self->generator;
            state $data;
            while ($data = $next->()) {
                $sub->($data) || return $data;
            }
            return;
        };
    });
}

sub pluck {
    my ($self, $key) = @_;
    Catmandu::Iterator->new(sub {
        sub {
            state $next = $self->generator;
            ($next->() || return)->{$key};
        };
    });
}

sub includes {
    my ($self, $data) = @_;
    $self->any(sub {
        Data::Compare::Compare($data, $_[0]);
    });
}

1;

=head1 NAME

Catmandu::Iterable - provide collection methods to any package providing an C<each> method

=head1 SYNOPSIS

    package Collection;

    use parent 'Catmandu::Iterable';

    sub each {
        my ($self, $sub) = @_;
        my $collection = [{foo => 'oof'}, {bar => 'rab'}, {baz => 'zab'}];
        $sub->($_) for @$collection;
        scalar @$collection;
    }

    package main;

    Collection->any(sub { exists $_[0]->{bar} });
    => 1
    Collection->take(2);
    => [{foo => 'foo'}, {bar => 'bar'}];

=head1 SEE ALSO

L<Catmandu::Iterator>.

=cut

