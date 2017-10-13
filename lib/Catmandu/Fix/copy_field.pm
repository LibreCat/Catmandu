package Catmandu::Fix::copy_field;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Moo;
use Catmandu::Util qw(as_path);
use Clone qw(clone);
use namespace::clean;
use Catmandu::Fix::Has;

has old_path => (fix_arg => 1, coerce => \&as_path);
has new_path => (fix_arg => 1, coerce => \&as_path);
has getter => (is => 'lazy');
has creator => (is => 'lazy');

sub _build_getter {
    my ($self) = @_;
    $self->old_path->getter;
}

sub _build_creator {
    my ($self) = @_;
    $self->new_path->creator;
}

sub fix {
    my ($self, $data) = @_;
    my $vals = $self->getter->($data);
    while (@$vals) {
        $self->creator->($data, clone shift @$vals);
    }
    $data;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::copy_field - copy the value of one field to a new field

=head1 SYNOPSIS

   # Copy the values of foo.bar into bar.foo
   copy_field(foo.bar, bar.foo)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
