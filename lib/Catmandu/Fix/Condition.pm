package Catmandu::Fix::Condition;

use Catmandu::Sane;
use Moo::Role;

with 'Catmandu::Fix::Base';

has fixes      => (is => 'ro', default => sub { [] });
has else_fixes => (is => 'ro', default => sub { [] });

1;
