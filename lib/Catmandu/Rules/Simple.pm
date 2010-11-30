package Catmandu::Rules::Simple;

use 5.010;
use Moose;
use DBI;

with 'Catmandu::Rules';

my $SQL_CREATE_TABLE = "CREATE TABLE IF NOT EXISTS rules(subject TEXT NOT NULL, verb TEXT NOT NULL, object TEXT NOT NULL)";
my $SQL_CREATE_INDEX = "CREATE INDEX IF NOT EXISTS rules_index ON rules(subject, verb, object)";

my $SQL_ST_HAS_RULE    = "SELECT 1 FROM rules WHERE subject = ? AND verb = ? AND object = ? LIMIT 1";
my $SQL_ST_ADD_RULE    = "INSERT INTO rules(subject,verb,object) SELECT ?,?,? WHERE NOT EXISTS ($SQL_ST_HAS_RULE)";
my $SQL_ST_DELETE_RULE = "DELETE FROM rules WHERE subject = ? AND verb = ? AND object = ?";

has file => (is => 'ro', isa => 'Str', required => 1);
has _dbh => (is => 'ro', isa => 'Ref', required => 1, init_arg => undef, builder => '_build_dbh');

sub _build_dbh {
    my $self = shift;
    my $file = $self->file;

    my $dbh = DBI->connect("dbi:SQLite:dbname=$file", "", "");
    $dbh->{sqlite_unicode} = 1;
    $dbh->do($SQL_CREATE_TABLE) or confess $dbh->errstr;
    $dbh->do($SQL_CREATE_INDEX) or confess $dbh->errstr;
    $dbh;
}

sub has_rule {
    my ($self, $s, $v, $o) = @_;
    $s or confess "Missing subject";
    $v or confess "Missing verb";
    $o //= "";
    my $sth = $self->_dbh->prepare($SQL_ST_HAS_RULE);
    $sth->execute($s, $v, $o);
    $sth->fetchrow_arrayref ? 1 : 0;
}

sub add_rule {
    my ($self, $s, $v, $o) = @_;
    $s or confess "Missing subject";
    $v or confess "Missing verb";
    $o //= "";
    my $sth = $self->_dbh->prepare($SQL_ST_ADD_RULE);
    $sth->execute($s, $v, $o, $s, $v, $o);
    1;
}

sub delete_rule {
    my ($self, $s, $v, $o) = @_;
    $s or confess "Missing subject";
    $v or confess "Missing verb";
    $o //= "";
    my $sth = $self->_dbh->prepare($SQL_ST_DELETE_RULE);
    $sth->execute($s, $v, $o);
    1;
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

