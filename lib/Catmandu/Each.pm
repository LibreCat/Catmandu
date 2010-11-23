package Catmandu::Each;

use Moose::Role;

requires 'each';

sub to_array {
    my ($self, $sub) = @_;
    my $all = [];
    $self->each(sub {
        push @$all, $_[0];
    });
    $all;
}

sub all {
    my ($self, $sub) = @_;
    $self->each(sub {
        $sub->($_[0]) || goto(END);
    });
    return 1;
    END:
    return 0;
}

sub any {
    my ($self, $sub) = @_;
    $self->each(sub {
        $sub->($_[0]) && goto(END);
    });
    return 0;
    END:
    return 1;
}

sub many {
    my ($self, $sub) = @_;
    my $n = 0;
    $self->each(sub {
        $sub->($_[0]) && ++$n > 1 && goto(END);
    });
    return 0;
    END:
    return 1;
}

sub map {
    my ($self, $sub) = @_;
    my $all = [];
    $self->each(sub {
        push @$all, $sub->($_[0]);
    });
    $all;
}

sub detect {
    my ($self, $sub) = @_;
    my $val;
    $self->each(sub {
        $sub->($_[0]) || return;
        $val = $_[0];
        goto END;
    });
    END:
    $val;
}

sub select {
    my ($self, $sub) = @_;
    my $all = [];
    $self->each(sub {
        $sub->($_[0]) && push(@$all, $_[0]);
    });
    $all;
}

sub reject {
    my ($self, $sub) = @_;
    my $all = [];
    $self->each(sub {
        $sub->($_[0]) || push(@$all, $_[0]);
    });
    $all;
}

sub partition {
    my ($self, $sub) = @_;
    my $all_t = [];
    my $all_f = [];
    $self->each(sub {
        $sub->($_[0]) ? push(@$all_t, $_[0]) : push(@$all_f, $_[0]);
    });
    [ $all_t, $all_f ];
}

sub reduce {
    my $m = @_ == 3;
    my ($self, $memo, $sub);
    if ($m) {
        ($self, $memo, $sub) = @_;
    } else {
        ($self, $sub) = @_;
    }
    $self->each(sub {
        if ($m) {
            $memo = $sub->($memo, $_[0]);
        } else {
            $memo = $_[0];
            $m = 1;
        }
    });
    $memo;
}

sub each_slice {
    my ($self, $slice_size, $sub) = @_;
    my $slice = [];
    my $n = 0;
    $self->each(sub {
        push @$slice, $_[0];
        if (@$slice == $slice_size) {
            $sub->($slice);
            $slice = [];
            $n++;
        }
    });
    if (@$slice) {
        $sub->($slice);
        $n++;
    }
    $n;
}

sub slice {
    my ($self, $slice_size) = @_;
    my $all = [];
    $self->each_slice($slice_size, sub {
        push @$all, $_[0];
    });
    $all;
}

sub pluck {
    my ($self, $key) = @_;
    my $all = [];
    $self->each(sub {
        push @$all, $_[0]->{$key};
    });
    $all;
}

sub first {
    my ($self, $n) = @_;
    my $val;
    if (defined $n) {
        return $self->take($n);
    }
    $self->each(sub {
        $val = $_[0];
        goto END;
    });
    END:
    $val;
}

sub take {
    my ($self, $n) = @_;
    my $all = [];
    $self->each(sub {
        if ($n--) {
            push @$all, $_[0];
        }
        $n || goto(END);
    });
    END:
    $all;
}

no Moose::Role;
__PACKAGE__;

