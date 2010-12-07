use MooseX::Declare;

role Catmandu::Each {
    requires 'each';

    method to_array () {
        my $all = [];
        $self->each(sub {
            push @$all, $_[0];
        });
        $all;
    }

    method all (CodeRef $sub) {
        $self->each(sub {
            $sub->($_[0]) || goto(END);
        });
        return 1;
        END:
        return 0;
    }

    method any (CodeRef $sub) {
        $self->each(sub {
            $sub->($_[0]) && goto(END);
        });
        return 0;
        END:
        return 1;
    }

    method many (CodeRef $sub) {
        my $n = 0;
        $self->each(sub {
            $sub->($_[0]) && ++$n > 1 && goto(END);
        });
        return 0;
        END:
        return 1;
    }

    method map (CodeRef $sub) {
        my $all = [];
        $self->each(sub {
            push @$all, $sub->($_[0]);
        });
        $all;
    }

    method detect (CodeRef $sub) {
        my $val;
        $self->each(sub {
            $sub->($_[0]) || return;
            $val = $_[0];
            goto END;
        });
        END:
        $val;
    }

    method select (CodeRef $sub) {
        my $all = [];
        $self->each(sub {
            $sub->($_[0]) && push(@$all, $_[0]);
        });
        $all;
    }

    method reject (CodeRef $sub) {
        my $all = [];
        $self->each(sub {
            $sub->($_[0]) || push(@$all, $_[0]);
        });
        $all;
    }

    method partition (CodeRef $sub) {
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

    method each_slice (Int $size where { $_ > 0 }, CodeRef $sub) {
        my $slice = [];
        my $n = 0;
        $self->each(sub {
            push @$slice, $_[0];
            if (@$slice == $size) {
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

    method slice ($size) {
        my $all = [];
        $self->each_slice($size, sub {
            push @$all, $_[0];
        });
        $all;
    }

    method pluck ($key) {
        my $all = [];
        $self->each(sub {
            push @$all, $_[0]->{$key};
        });
        $all;
    }

    method first ($n?) {
        if (defined $n) {
            return $self->take($n);
        }
        my $val;
        $self->each(sub {
            $val = $_[0];
            goto END;
        });
        END:
        $val;
    }

    method take (Int $n where { $_ > 0 }) {
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
}

1;

