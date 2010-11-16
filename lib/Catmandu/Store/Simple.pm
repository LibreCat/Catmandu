package Catmandu::Store::Simple;

use Moose;
use Try::Tiny;
use Data::UUID;
use JSON ();
use DBI;

with 'Catmandu::Store';

has file => (is => 'ro', required => 1);
has _dbh => (is => 'ro', required => 1, init_arg => undef, builder => '_build_dbh');
has _transaction_running => (is => 'rw', isa => 'Bool', init_arg => undef);

sub _build_dbh {
    my $self = shift;
    my $file = $self->file;

    my $dbh = DBI->connect("dbi:SQLite:dbname=$file", "", "");
    $dbh->{sqlite_unicode} = 1;
    $dbh->do("CREATE TABLE IF NOT EXISTS objects(id TEXT PRIMARY KEY, data TEXT NOT NULL)") or
        confess $dbh->errstr;
    $dbh;
}

sub load {
    my ($self, $id) = @_;
    my $sth = $self->_dbh->prepare("SELECT data FROM objects WHERE id = ?");
    $sth->execute($id);
    my $row = $sth->fetchrow_arrayref || return;
    JSON::decode_json($row->[0]);
}

sub each {
    my ($self, $sub) = @_;
    my $sth = $self->_dbh->prepare("SELECT data FROM objects");
    $sth->execute;
    my $count = 0;
    my $row;
    while ($row = $sth->fetchrow_arrayref) {
        $sub->(JSON::decode_json($row->[0]));
        $count++;
    }
    $count;
}

sub save {
    my ($self, $obj) = @_;
    my $id = $obj->{_id} ||= Data::UUID->new->create_str;
    my $json = JSON::encode_json($obj);
    my $sth = $self->_dbh->prepare("INSERT OR REPLACE INTO objects VALUES(?,?)");
    $sth->execute($id, $json);
    $obj;
}

sub delete {
    my ($self, $obj) = @_;
    my $id = ref $obj eq 'HASH' ? $obj->{_id} :
                                  $obj;
    $id or confess "Missing _id";
    my $sth = $self->_dbh->prepare("DELETE FROM objects WHERE id = ?");
    $sth->execute($id);
}

sub transaction {
    my ($self, $sub) = @_;

    return $sub->() if $self->_transaction_running;

    my $dbh = $self->_dbh;
    try {
        $self->_transaction_running(1);
        $dbh->begin_work;
        my $val = $sub->();
        $dbh->commit;
        $val;
    } catch {
        $dbh->rollback;
        confess $_;
    } finally {
        $self->_transaction_running(0);
    };
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

__END__

=head1 NAME

Catmandu::Store::Simple - an implementation of L<Catmandu::Store> backed by L<DBD::SQLite>.

=head1 SYNOPSIS

    use Catmandu::Store::Simple

    my $store = Catmandu::Store::Simple->new(file => '/tmp/store.db');

=head1 DESCRIPTION

See L<Catmandu::Store>.

=head1 METHODS

See L<Catmandu::Store> for the base methods.

Extra methods for this class:

=head2 Class->new(%args)

Takes the following arguments:

file: The path to the sqlite3 database (required)

=head2 $c->file

Return the path to the underlying sqlite3 database as a string.

=head2 $c->transaction($sub)

Wraps the store actions in C<$sub> in a transaction:

    # no records will be created:
    $store->transaction(sub {
        $store->save({_id => "1"});
        $store->save({_id => "2"});
        $store->save({_id => "3"});
        die "horribly";
    });

Nested transactions aren't supported, they are subsumed by
their parent transaction.

=head1 SEE ALSO

L<Catmandu::Store>, the Store role.

L<DBD::SQLite>, the underlying database driver.

