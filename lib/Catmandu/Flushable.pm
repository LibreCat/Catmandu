package Catmandu::Flushable;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo::Role;
use namespace::clean;

requires 'commit';
requires 'flush';

before commit => sub {
    $_[0]->flush;
};

1;

__END__

=pod

=head1 NAME

Catmandu::Flushable - Optional role for flushable bags

=head1 DESCRIPTION

C<flush> makes sure that data added get persisted to disk for stores that
support this operation (e.g. Elasticsearch).

This role also installs a hook that calls C<flush> on C<commit>.

=head1 SYNOPSIS

    $store->bag->flush;

=head1 METHODS

=head2 flush

Flush the bag.

=cut

