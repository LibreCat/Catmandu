package Hepcat::Controller::Main;
use Dancer ':syntax';

our $VERSION = '0.1';

get '/' => sub {
    session q => undef;
    template 'index';
};

before_template sub {
    my $tokens = shift;
    $tokens->{config} = config;
};

1;

