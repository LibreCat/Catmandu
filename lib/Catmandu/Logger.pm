package Catmandu::Logger;

use namespace::clean;
use Catmandu::Sane;
use Moo::Role;
use Log::Any ();

local $| = 1;

has 'log' => (is => 'lazy');

sub _build_log {
    my ($self) = @_;
    Log::Any->get_logger(category => ref($self));
}

1;
