package Catmandu::Fixer;
use Catmandu::Util qw(is_able is_value);
use Catmandu::Class;
use Catmandu::Iterator;
use File::Slurp qw(slurp);
use Clone qw(clone);

{
    package Catmandu::Fixer::Context;
    use Catmandu::Sane;
    use Catmandu::Util;
    use JSON::Path;

    my @FIXES;

    sub LOAD_FIXES {
        @FIXES = ();
        for (@_) {
            eval $_; confess $@ if $@;
        }
        @FIXES;
    }

    sub J {
        JSON::Path->new($_[0]);
    }

    sub DESTROY {}

    sub AUTOLOAD {
        my ($fix) = our $AUTOLOAD =~ /::(\w+)$/;

        my $pkg = Catmandu::Util::load_package($fix, 'Catmandu::Fix');
        my $sub = sub {
            push @FIXES, $pkg->new(@_);
        };

        { no strict 'refs'; *$AUTOLOAD = $sub };

        $sub->(@_);
    }
};

sub build_args {
    my ($self, @args) = @_;
    my $fixes = [];
    for my $arg (@args) {
        if (is_able($arg, 'fix')) {
            push @$fixes, $arg;
        } elsif (is_value($arg) && -f $arg) {
            push @$fixes, Catmandu::Fixer::Context::LOAD_FIXES(slurp($arg));
        } elsif (is_value($arg)) {
            push @$fixes, Catmandu::Fixer::Context::LOAD_FIXES($arg);
        }
    }

    { fixes => $fixes };
}

sub fix {
    my ($self, $obj) = @_;

    my @fixes = @{$self->{fixes}};

    if (ref $obj eq 'HASH') {
        $obj = clone($obj);
        for my $fix (@fixes) {
            $fix->fix($obj);
        }
        return $obj;
    }

    if (ref $obj eq 'ARRAY') {
        return [ map {
            my $o = clone($_);
            for my $fix (@fixes) {
                $fix->fix($o);
            }
            $o;
        } @$obj ];
    }

    if (is_able($obj, 'each')) {
        return Catmandu::Iterator->new(sub {
            my $sub = $_[0];
            $obj->each(sub {
                my $o = clone($_[0]);
                for my $fix (@fixes) {
                    $fix->fix($o);
                }
                $sub->($o);
            });
        });
    }

    confess "Invalid object";
}

no Catmandu::Util;
no File::Slurp;
no Clone;
1;
