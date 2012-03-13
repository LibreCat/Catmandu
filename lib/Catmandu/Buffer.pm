package Catmandu::Buffer;

use Catmandu::Sane;
use Moo::Role;

has buffer_size => (is => 'ro', builder => 'default_buffer_size');
has buffer => (is => 'ro', lazy => 1, default => sub { [] });

sub default_buffer_size { 100 }

sub clear_buffer {
    $_[0]->{buffer} = [];
}

sub buffer_used {
    scalar @{$_[0]->buffer};
}

sub buffer_is_full {
    my $self = $_[0];
    $self->buffer_used >= $self->buffer_size ? 1 : 0;
}

sub buffer_add {
    my $buffer = shift->buffer;
    push @$buffer, @_;
}

1;
