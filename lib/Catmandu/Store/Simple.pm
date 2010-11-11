package Catmandu::Store::Simple;

use Any::Moose;
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
no Any::Moose;
__PACKAGE__;

