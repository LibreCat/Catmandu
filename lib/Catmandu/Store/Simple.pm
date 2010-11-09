package Catmandu::Store::Simple;

use Any::Moose;
use Data::UUID;
use JSON ();
use DBI;
use Try::Tiny;

with 'Catmandu::Store';

has file => (is => 'ro', required => 1);
has _dbh => (is => 'ro', required => 1, init_arg => undef, builder => '_build_dbh');

sub _build_dbh {
    my $self = shift;
    my $file = $self->file;
    my $_dbh = DBI->connect("dbi:SQLite:dbname=$file", "", "");
    $_dbh->{sqlite_unicode} = 1;
    $_dbh->do("CREATE TABLE IF NOT EXISTS objects(id TEXT PRIMARY KEY, data TEXT NOT NULL)") or
        confess $_dbh->errstr;
    $_dbh;
}

sub save {
    my ($self, $obj) = @_;
    my $id = $obj->{_id} ||= Data::UUID->new->create_str;
    my $json = JSON::encode_json($obj);
    my $sth = $self->_dbh->prepare("INSERT OR REPLACE INTO objects VALUES(?,?)");
    $sth->execute($id, $json);
    $obj;
}

sub load {
    my ($self, $id) = @_;
    my $sth = $self->_dbh->prepare("SELECT data FROM objects WHERE id = ?");
    $sth->execute($id);
    my ($json) = $sth->fetchrow_array;
    $json or return;
    JSON::decode_json($json);
}

sub delete {
    my ($self, $obj) = @_;
    my $id = ref $obj eq 'HASH' ? $obj->{_id} :
                                  $obj;
    $id or confess "Missing _id";
    my $sth = $self->_dbh->prepare("DELETE FROM objects WHERE id = ?");
    $sth->execute($id);
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
__PACKAGE__;

