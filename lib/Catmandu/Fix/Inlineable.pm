package Catmandu::Fix::Inlineable;

use Catmandu::Sane;

our $VERSION = '1.0603';

use Clone qw(clone);
use Moo::Role;
use namespace::clean;

requires 'fix';

sub import {
    my $target = caller;
    my ($pkg, %opts) = @_;

    if (my $sym = $opts{as}) {
        $opts{cache} //= 1;

        my $sub = sub {
            my $data = shift;
            my $fixer;

            state $cache = {};
            if ($opts{cache}) {
                my $key = join('--', @_);
                $fixer = $cache->{$key} ||= do {
                    my $f = $pkg->new(@_);

                    # memoize instance of Fix.pm if it's an emitting fix
                    $f = $f->fixer if $f->can('fixer');
                    $f;
                };
            }

            $fixer ||= $pkg->new(@_);

            if ($opts{clone}) {
                $data = clone($data);
            }

            $fixer->fix($data);
        };
        no strict 'refs';
        *{"${target}::$sym"} = $sub;
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Inlineable - Role for all Catmandu fixes that can be inlined

=head1 SYNOPSIS

    package Catmandu::Fix::my_fix1;

    use Catmandu::Sane;
    use Moo;

    with 'Catmandu::Fix::Inlineable';

    sub fix {
        my ($self, $data) = @_;
        ....FIXER GENERATING CODE....
        $data
    }

    package Catmandu::Fix::my_fix2;

    use Catmandu::Sane;
    use Moo;

    # Catmandu::Fix::Base automatically is Inlineable
    with 'Catmandu::Fix::Base';

    sub emit {
        my ($self, $fixer) = @_;
        ....FIXER GENERATING CODE....
    }

    package main;

    use Catmandu::Fix::my_fix1 as => 'my_fix1';
    # disabling caching may be desirable with fixes that have side effects like
    # writing to a file, the downside is that a new instance of the fix will be
    # created with each invocation
    use Catmandu::Fix::my_fix2 as => 'my_fix2', cache => 0;

    my $data = {};

    $data = my_fix1($data);
    $data = my_fix2($data);

=head1 SEE ALSO

For more information how to create fixes read the following two blog posts:

http://librecat.org/catmandu/2014/03/14/create-a-fixer.html
http://librecat.org/catmandu/2014/03/26/creating-a-fixer-2.html

=cut
