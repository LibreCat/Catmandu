package Catmandu::Fix::Has;

use Catmandu::Sane;

our $VERSION = '1.0604';

use Class::Method::Modifiers qw(install_modifier);

sub import {
    my $target = caller;

    my $around   = do {no strict 'refs'; \&{"${target}::around"}};
    my $fix_args = [];
    my $fix_opts = [];

    install_modifier(
        $target, 'around', 'has',
        sub {
            my ($orig, $attr, %opts) = @_;

            return $orig->($attr, %opts)
                unless exists $opts{fix_arg} || exists $opts{fix_opt};

            $opts{is} //= 'ro';
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
        }
    );

    $around->(
        'BUILDARGS',
        sub {
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
                }
                elsif (exists $orig_args->{"-$key"}) {
                    $args->{$key} = delete $orig_args->{"-$key"};
                }
                elsif (exists $orig_args->{$key}) {
                    $args->{$key} = delete $orig_args->{$key};
                }
            }

            $args;
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Has - helper class for creating Fix-es with (optional) parameters

=head1 SYNOPSIS

    package Catmandu::Fix::foo;
    use Moo;
    use Catmandu::Fix::Has;

    has greeting => (fix_arg => 1);   # required parameter 1
    has message  => (fix_arg => 1);   # required parameter 2
    has eol      => (fix_opt => 1 , default => sub {'!'} ); # optional parameter 'eol' with default '!'

    sub fix {
        my ($self,$data) = @_;

        print STDERR $self->greeting . ", " . $self->message . $self->eol . "\n";

        $data;
    }

    1;

=head1 PARAMETERS

=over 4

=item fix_arg 

Required argument when set to 1. The Fix containing the code fragment below needs 
two arguments.

    use Catmandu::Fix::Has;

    has message => (fix_arg => 1); # required parameter 1
    has number  => (fix_arg => 1); # required parameter 2

When the fix_arg is set to 'collect', then all arguments are read into an
array. The Fix containing the code fragment below needs at least 1 or more
arguments. All arguments will get collected into the C<messages> array:

    use Catmandu::Fix::Has;

    has messages => (fix_arg => 'collect'); # required parameter

=item fix_opt

Optional named argument when set to 1. The Fix containing the code fragment
below can have two optional arguments C<message: ...>, C<number: ...>:

    use Catmandu::Fix::Has;

    has message => (fix_opt => 1); # optional parameter 1
    has number  => (fix_opt => 1); # optional parameter 2

When the fix_opt is set to 'collect', then all optional argument are read into
an array. The Fix containing the code fragment below needs at least 1 or more
arguments. All arguments will get collected into the C<options> array:

    use Catmandu::Fix::Has;

    has options => (fix_opt => 'collect'); # optional parameter

=back

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

