package Catmandu::Fix::Base;

use Catmandu::Sane;
use Catmandu::Fix;
use Clone ();
use Moo::Role;
use namespace::clean;

with 'MooX::Log::Any';

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
