package Dancer::Plugin::MultiValueParams;
use strict;
use warnings;
use Dancer qw(:syntax);
use Dancer::Plugin;
use Hash::MultiValue;

our $VERSION = '0.1';

register parameters => sub {
    vars->{multi_value_params} ||= do {
        my $params = params; Hash::MultiValue->from_mixed($params);
    };
};

register_plugin;

1;
