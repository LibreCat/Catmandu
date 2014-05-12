package Catmandu::Fix::Has;

use Catmandu::Sane;
use Class::Method::Modifiers qw(install_modifier);
use namespace::clean;

sub import {
    my $target = caller;

    my $around = do { no strict 'refs'; \&{"${target}::around"} };
    my $fix_args = [];
    my $fix_opts = [];

    install_modifier($target, 'around', 'has', sub {
        my ($orig, $attr, %opts) = @_;

        return $orig->($attr, %opts)
            unless exists $opts{fix_arg} || exists $opts{fix_opt};

        $opts{is}       //= 'ro';
        $opts{init_arg} //= $attr;

        my $arg = {key => $opts{init_arg}};

        if ($opts{fix_arg}) {
            $opts{required} //= 1;
            $arg->{collect} = 1 if $opts{fix_arg} eq 'collect';
            push @$fix_args, $arg;
            delete $opts{fix_arg};
        }

        if ($opts{fix_opt}) {
            $arg->{collect} = 1 if $opts{fix_opt} eq 'collect';
            push @$fix_opts, $arg;
            delete $opts{fix_opt};
        }

        $orig->($attr, %opts);
    });

    $around->('BUILDARGS', sub {
        my $orig = shift;
        my $self = shift;

        return $orig->($self, @_) unless @$fix_args || @$fix_opts;

        my $args = {};

        for my $arg (@$fix_args) {
            last unless @_;
            my $key = $arg->{key};
            if ($arg->{collect}) {
                $args->{$key} = [splice @_, 0, @_];
                last;
            }
            $args->{$key} = shift;
        }

        my $orig_args = $self->$orig(@_);

        for my $arg (@$fix_opts) {
            my $key = $arg->{key};
            if ($arg->{collect}) {
                $args->{$key} = $orig_args;
                last;
            } elsif (exists $orig_args->{"-$key"}) {
                $args->{$key} = delete $orig_args->{"-$key"};
            } elsif (exists $orig_args->{$key}) {
                $args->{$key} = delete $orig_args->{$key};
            }
        }

        $args;
  });
}

1;

