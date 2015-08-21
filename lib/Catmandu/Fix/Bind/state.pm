package Catmandu::Fix::Bind::state;

use Moo;

with 'Catmandu::Fix::Bind';

has field  => (is => 'ro');

our $state = { };

sub unit {
    my ($self,$data) = @_;

    my $field = $self->field;

    unless (exists $state->{$field}) {
        $state->{$field} = {};
    }

    $data->{$field} = $state->{$field};

    $data;
}

sub bind {
    my ($self,$mvar,$func) = @_;

    $func->($mvar);
}

sub result {
    my ($self,$mvar,$func) = @_;
    my $field = $self->field;

    delete $mvar->{$field};

    $mvar;
}

=head1 NAME

Catmandu::Fix::Bind::state - a binder that keeps a global state

=head1 SYNOPSIS

    do state(field => 'global')
        copy_field(name, global.name.$append) # write into the global record
    
        copy_field(global.name, result)       # read from the global record
    end

=head1 DESCRIPTION

The state binder will create a global record for reference. Based on a field name one can read and write
to this global record. The content of this global record will not be exported if not explicitly imported
into the record.

=head1 CONFIGURATION

=head2 field 

The field name that contains the global record.

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut

1;
