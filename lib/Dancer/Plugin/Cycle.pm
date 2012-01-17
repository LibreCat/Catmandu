package Dancer::Plugin::Cycle;

our $VERSION = '0.1';

use strict;
use warnings;
use Dancer qw(:syntax);
use Dancer::Plugin;

my $cycle = [];
my $i = 0;

sub cycle {
    if (@_) {
        $cycle = [@_];
        $i = 0;
        return;
    }
    if ($i == @$cycle) {
        $i = 0;
    }
    $cycle->[$i++];
}

before_template sub {
    $_[0]->{cycle} = \&cycle;
};

register cycle => \&cycle;

register_plugin;

1;
