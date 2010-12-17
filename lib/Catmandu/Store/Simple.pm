package Catmandu::Store::Simple;
# ABSTRACT: A Catmandu::Store backed by DBD::SQLite
# VERSION
use namespace::autoclean;
use Moose;
use Try::Tiny;
use Data::UUID;
use JSON ();
use DBI;

with qw(Catmandu::Store);

my $SQL_CREATE_TABLE = "CREATE TABLE IF NOT EXISTS objects(id TEXT PRIMARY KEY, data TEXT NOT NULL)";

my $SQL_ST_LOAD   = "SELECT data FROM objects WHERE id = ?";
my $SQL_ST_EACH   = "SELECT data FROM objects";
my $SQL_ST_SAVE   = "INSERT OR REPLACE INTO objects VALUES(?,?)";
my $SQL_ST_DELETE = "DELETE FROM objects WHERE id = ?";

has path => (is => 'ro', isa => 'Str', required => 1);

has _dbh => (is => 'ro', isa => 'Ref', required => 1, init_arg => undef, builder => '_build_dbh');

has _sth_load   => (is => 'ro', lazy => 1, init_arg => undef, default => sub { $_[0]->_dbh->prepare($SQL_ST_LOAD) });
has _sth_each   => (is => 'ro', lazy => 1, init_arg => undef, default => sub { $_[0]->_dbh->prepare($SQL_ST_EACH) });
has _sth_save   => (is => 'ro', lazy => 1, init_arg => undef, default => sub { $_[0]->_dbh->prepare($SQL_ST_SAVE) });
has _sth_delete => (is => 'ro', lazy => 1, init_arg => undef, default => sub { $_[0]->_dbh->prepare($SQL_ST_DELETE) });

has _in_transaction => (is => 'rw', isa => 'Bool', init_arg => undef);

sub _build_dbh {
    my $self = shift;
    my $path = $self->path;

    my $dbh = DBI->connect("dbi:SQLite:dbname=$path", "", "");
    $dbh->{sqlite_unicode} = 1;
    $dbh->do($SQL_CREATE_TABLE) or confess $dbh->errstr;
    $dbh;
}

sub load {
    my ($self, $id) = @_;
    my $row = $self->_dbh->selectrow_arrayref($self->_sth_load, {}, $self->need_id($id)) || return;
    my $obj = JSON::decode_json($row->[0]);
    $obj;
}

sub each {
    my ($self, $sub) = @_;
    my $sth = $self->_sth_each;
    $sth->execute;
    my $n = 0;
    while (my $row = $sth->fetchrow_arrayref) {
        $sub->(JSON::decode_json($row->[0]));
        $n++;
    }
    $n;
}

sub save {
    my ($self, $obj) = @_;
    my $id   = $obj->{$self->id_field} ||= Data::UUID->new->create_str;
    my $json = JSON::encode_json($obj);
    $self->_sth_save->execute($id, $json);
    $obj;
}

sub delete {
    my ($self, $id) = @_;
    $self->_sth_delete->execute($self->need_id($id));
}

sub transaction {
    my ($self, $sub) = @_;

    return $sub->() if $self->_in_transaction;

    my $dbh = $self->_dbh;
    try {
        $self->_in_transaction(1);
        $dbh->begin_work;
        my $val = $sub->();
        $dbh->commit;
        $val;
    } catch {
        $dbh->rollback;
        confess $_;
    } finally {
        $self->_in_transaction(0);
    };
}

__PACKAGE__->meta->make_immutable;

1;

=head1 SYNOPSIS

    use Catmandu::Store::Simple

    my $store = Catmandu::Store::Simple->new(path => '/tmp/store.db');

=head1 DESCRIPTION

See L<Catmandu::Store>.

=head1 METHODS

See L<Catmandu::Store> for the base methods.

Extra methods for this class:

=head2 Class->new(%args)

Takes the following arguments:

path: The path to the sqlite3 database (required)

=head2 $c->path

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

