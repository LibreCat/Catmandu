package Hepcat::Controller::Main;
use Dancer ':syntax';

our $VERSION = '0.1';

get '/' => sub {
    session q => undef;
    template 'index';
};

1;

