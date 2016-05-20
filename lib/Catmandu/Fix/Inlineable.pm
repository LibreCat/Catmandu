package Catmandu::Fix::Inlineable;

use Catmandu::Sane;

our $VERSION = '1.02';

use Catmandu::Fix;
use Clone ();
use Moo::Role;
use namespace::clean;

with 'Catmandu::Logger';

sub import {
    my $target = caller;
    my ($fix, %opts) = @_;

    if (my $sym = $opts{as}) {
        my $sub = sub {
            my $data = shift;
            if ($opts{clone}) {
                $data = Clone::clone($data);
            }
            $fix->new(@_)->fix($data);
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

    # Catmandu::Fix::Base automatcally is Inlineable
    with 'Catmandu::Fix::Base';

    sub emit {
        my ($self, $fixer) = @_;
        ....FIXER GENERATING CODE....
    }

    package main;

    use Catmandu::Fix::my_fix1 as => 'my_fix1';
    use Catmandu::Fix::my_fix2 as => 'my_fix2';

    my $data = {};

    $data = my_fix1($data);
    $data = my_fix2($data);

=head1 SEE ALSO

For more information how to create fixes read the following two blog posts:

http://librecat.org/catmandu/2014/03/14/create-a-fixer.html
http://librecat.org/catmandu/2014/03/26/creating-a-fixer-2.html

=cut
