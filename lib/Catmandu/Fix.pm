package Catmandu::Fix::EvalContext;
use Catmandu::Sane;
use Catmandu::Util;
use JSON::Path;

my @__FIXES;

sub __EVAL_FIXES {
    @__FIXES = ();
    for my $fix (@_) {
        eval $fix; confess $@ if $@;
    }
    @__FIXES;
}

sub j {
    my $path = $_[0];
    $path = "\$$path" unless $path && $path =~ /^\$/;
    JSON::Path->new($path);
}

sub AUTOLOAD {
    my ($fix) = our $AUTOLOAD =~ /::(\w+)$/;

    my $pkg = Catmandu::Util::load_package($fix, 'Catmandu::Fix');
    my $sub = sub {
        push @__FIXES, $pkg->new(@_);
    };

    { no strict 'refs'; *$AUTOLOAD = $sub };

    $sub->(@_);
}

sub DESTROY {}

package Catmandu::Fix;
use Catmandu::Sane;
use Catmandu::Object;
use Catmandu::Util qw(quacks value);
use Catmandu::Iterator;
use File::Slurp qw(read_file);

sub _build_args {
    my ($self, @args) = @_;

    my $fixes = [];

    for my $arg (@args) {
        if (quacks $arg, 'fix') {
            push @$fixes, $arg;
        } elsif (value $arg and -f $arg) {
            push @$fixes, Catmandu::Fix::EvalContext::__EVAL_FIXES(read_file($arg));
        } elsif (value $arg) {
            push @$fixes, Catmandu::Fix::EvalContext::__EVAL_FIXES($arg);
        }
    }

    { fixes => $fixes };
}

sub fix {
    my ($self, $obj) = @_;

    my $fixes = $self->{fixes};

    if (quacks $obj, 'each') {
        return Catmandu::Iterator->new(sub {
            my $sub = $_[0];
            $obj->each(sub {
                my $o = $_[0];
                for my $fix (@$fixes) {
                    $o = $fix->fix($o);
                }
                $sub->($o);
            });
        });
    }

    for my $fix (@$fixes) {
        $obj = $fix->fix($obj);
    }
    $obj;
}

1;
