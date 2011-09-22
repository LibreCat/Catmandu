package Dancer::Plugin::Cycle;
use strict;
use warnings;
use Dancer qw(:syntax);
use Dancer::Plugin;

our $VERSION = '0.1';

my $cycle = [];
my $i = 0;

sub cycle {
    if (@_) {
        $cycle = [@_];
        $i = 0;
        return;
    }
    $i = 0 if $i == @$cycle;
    $cycle->[$i++];
}

before_template sub {
    $_[0]->{cycle} = \&cycle;
};

register cycle => \&cycle;

register_plugin;

1;
