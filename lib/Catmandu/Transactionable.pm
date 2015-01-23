package Catmandu::Transactionable;

use namespace::clean;
use Catmandu::Sane;
use Role::Tiny;

requires 'transaction';

1;

=head1 NAME

Catmandu::Transactionable - Base class for all Catmandu classes that support transactions (mostly Catmandu::Store)

=head1 SEE ALSO

L<Catmandu::Iterator>.

=cut

