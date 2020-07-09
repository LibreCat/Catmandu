package Catmandu::Fix::copy_field;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use Clone qw(clone);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has old_path => (fix_arg => 1);
has new_path => (fix_arg => 1);

sub _build_fixer {
    my ($self)   = @_;
    my $old_path = as_path($self->old_path);
    my $new_path = as_path($self->new_path);
    my $getter   = $old_path->getter;
    my $creator  = $new_path->creator;

    sub {
        my $data   = $_[0];
        my $values = [map {clone($_)} @{$getter->($data)}];
        while (@$values) {
            $data = $creator->($data, shift @$values);
        }
        $data;
    };
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
