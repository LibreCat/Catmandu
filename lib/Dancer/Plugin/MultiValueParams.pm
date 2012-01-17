package Dancer::Plugin::MultiValueParams;

our $VERSION = '0.1';

use strict;
use warnings;
use Dancer::Plugin;
use Dancer qw(:syntax);
use Hash::MultiValue;

register parameters => sub {
    vars->{_parameters} ||= Hash::MultiValue->from_mixed(params);
};

register_plugin;

1;
