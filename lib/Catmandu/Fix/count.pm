package Catmandu::Fix::count;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Moo;
use Catmandu::Util qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1, coerce => \&as_path);
has updater => (is => 'lazy');

sub _build_updater {
    my ($self) = @_;
    $self->path->updater(
        if => [
            array_ref => sub {scalar @{$_[0]}},
            hash_ref  => sub {scalar keys %{$_[0]}},
        ],
    );
}

sub fix {
    $_[0]->updater->($_[1]);
    $_[1];
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::count - replace the value of an array or hash field with its count

=head1 SYNOPSIS

   # e.g. tags => ["foo", "bar"]
   count(tags) # tags => 2

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
