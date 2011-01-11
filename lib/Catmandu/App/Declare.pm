package Catmandu::App::Declare;
# VERSION
use strict;
use warnings;
use Catmandu;
use Catmandu::App;

sub import {
    strict->import;
    warnings->import;

    my $pkg = caller;

    my @traits;
    my $app;

    no strict 'refs';

    *{"${pkg}::app"} = sub { $app ||=  };
}

1;

__END__

package App;

on '/foo' => foo =>
    get => sub {
        my ($self) = shift;
    };
