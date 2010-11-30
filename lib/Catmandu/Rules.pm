package Catmandu::Rules;

use Moose::Role;

requires 'has_rule';
requires 'add_rule';
requires 'delete_rule';

sub has_no_rule {
    my $self = shift; ! $self->has_rule(@_);
}

no Moose::Role;
__PACKAGE__

