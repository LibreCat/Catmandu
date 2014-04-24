package Catmandu::Fix::Condition;

use Catmandu::Sane;
use Moo::Role;

with 'Catmandu::Fix::Base';

has pass_fixes => (is => 'rw', default => sub { [] });
has fail_fixes => (is => 'rw', default => sub { [] });

1;
