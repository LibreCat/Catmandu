package Catmandu::Fix::Base;

=head1 NAME

Catmandu::Fix::Base - Base class for all code emitting Catmandu fixes

=head1 SYNOPSIS

    package Catmandu::Fix::my_fix;

    use Catmandu::Sane;
    use Moo;

    with 'Catmandu::Fix::Base';

    sub emit {
        my ($self, $fixer) = @_;
        ....FIXER GENERATING CODE....
    }

=head1 SEE ALSO

For more information how to create fixes read the following two blog posts:

http://librecat.org/catmandu/2014/03/14/create-a-fixer.html
http://librecat.org/catmandu/2014/03/26/creating-a-fixer-2.html
=cut

use Catmandu::Sane;
use Catmandu::Fix;
use Clone ();
use Moo::Role;
use namespace::clean;

with 'Catmandu::Logger';

requires 'emit';

has fixer => (is => 'lazy', init_arg => undef);

sub _build_fixer {
    my ($self) = @_;
    Catmandu::Fix->new(fixes => [$self]);
}

sub fix {
    my ($self, $data) = @_;
    $self->fixer->fix($data);
}

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
