package Catmandu::Iterable;
use Catmandu::Sane;
use Catmandu::Iterator;

sub each {}

sub to_array {
    my ($self) = @_;
    my $all = [];
    $self->each(sub {
        push @$all, $_[0];
    });
    $all;
}

sub slice {
    my ($self, $skip, $size) = @_;
    $size //= -1;
    Catmandu::Iterator->new(sub {
        return 0 if $size == 0;
        my $sub = $_[0];
        my $n = 0;
        $self->each(sub {
            if ($skip > 0) {
                $skip--;
            } else {
                $sub->($_[0]);
                if (++$n == $size) {
                    goto STOP_EACH;
                }
            }
        });
        STOP_EACH:
        $n;
    });
}

sub all {
    my ($self, $sub) = @_;
    $self->each(sub {
        $sub->($_[0]) || goto(STOP_EACH);
    });
    return 1;
    STOP_EACH:
    return 0;
}

sub any {
    my ($self, $sub) = @_;
    $self->each(sub {
        $sub->($_[0]) && goto(STOP_EACH);
    });
    return 0;
    STOP_EACH:
    return 1;
}

sub many {
    my ($self, $sub) = @_;
    my $n = 0;
    $self->each(sub {
        $sub->($_[0]) && ++$n > 1 && goto(STOP_EACH);
    });
    return 0;
    STOP_EACH:
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
        goto STOP_EACH;
    });
    STOP_EACH:
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
    my $self = shift;
    my $sub  = pop;
    my $memo = pop;
    my $memo_set = defined $memo;
    $self->each(sub {
        if ($memo_set) {
            $memo = $sub->($memo, $_[0]);
        } else {
            $memo = $_[0];
            $memo_set = 1;
        }
    });
    $memo;
}

sub each_group {
    my ($self, $size, $sub) = @_;
    my $group = [];
    my $n = 0;
    $self->each(sub {
        push @$group, $_[0];
        if (@$group == $size) {
            $sub->($group);
            $group = [];
            $n++;
        }
    });
    if (@$group) {
        $sub->($group);
        $n++;
    }
    $n;
}

sub group {
    my ($self, $size) = @_;
    my $all = [];
    $self->each_group($size, sub {
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
    if (defined $n) {
        return $self->take($n);
    }
    my $val;
    $self->each(sub {
        $val = $_[0];
        goto STOP_EACH;
    });
    STOP_EACH:
    $val;
}

sub take {
    my ($self, $n) = @_;
    my $all = [];
    $self->each(sub {
        if ($n--) {
            push @$all, $_[0];
        }
        $n || goto(STOP_EACH);
    });
    STOP_EACH:
    $all;
}

1;
