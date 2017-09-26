package Catmandu::Transactional;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Moo::Role;
use namespace::clean;

requires 'transaction';

1;

__END__

=pod

=head1 NAME

Catmandu::Transactional - Optional role for transactional stores

=head1 SYNOPSIS

    # bag will be untouched
    my $store->transaction(sub {
        $store->bag('books')->add({title => 'Time must have a stop'});
        die;
    });

=head1 METHODS

=head2 transaction($sub)

C<transaction> takes a coderef that will be executed in the context of a
transaction. If an error is thrown, the transaction will rollback. If the code
executes successfully, the transaction will be committed. There is no support
for nested transactions, nested calls to C<transaction> will simply be subsumed
by their parent transaction.

=cut
