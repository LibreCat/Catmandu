package Catmandu::Store::DBI;

use Catmandu::Sane;
use Moo;
use DBI;

with 'Catmandu::Store';

has data_source => (is => 'ro', required => 1);
has username    => (is => 'ro', default => sub { '' });
has password    => (is => 'ro', default => sub { '' });

has dbh => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_dbh',
);

sub _build_dbh {
    my $self = $_[0];
    DBI->connect($self->data_source, {
        Username => $self->username,
        Password => $self->password,
        AutoCommit => 1,
        RaiseError => 1,
    });
}

sub transaction {
    my ($self, $sub) = @_;

    my $dbh = $self->dbh;

    if (!$dbh->{AutoCommit}) {
        return $sub->();
    }

    my @res;

    eval {
        $dbh->{AutoCommit} = 0;
        $dbh->begin_work;
        @res = $sub->();
        $dbh->commit;
        $dbh->{AutoCommit} = 1;
        1;
    } or do {
        my $error = $@;
        eval { $dbh->rollback };
        $dbh->{AutoCommit} = 1;
        confess $error;
    };

    @res;
}

sub DEMOLISH {
    $_[0]->dbh->disconnect;
}

package Catmandu::Store::DBI::Bag;

use Catmandu::Sane;
use JSON qw(encode_json decode_json);
use Moo;

with 'Catmandu::Bag';

has _sth_get        => (is => 'ro', builder => '_build_sth_get');
has _sth_delete     => (is => 'ro', builder => '_build_sth_delete');
has _sth_delete_all => (is => 'ro', builder => '_build_sth_delete_all');
has _dbh_add        => (is => 'ro', builder => '_build_dbh_add');

sub BUILD {
    my $self = $_[0];
    my $name = $self->name;
    $self->store->dbh->do("create table if not exists $name(id varchar(255) not null primary key, data text not null)") or
        confess $self->store->dbh->errstr;
}

sub _build_sth_get {
    my $self = $_[0];
    my $name = $self->name;
    $self->store->dbh->prepare("select data from $name where id = ?");
}

sub _build_sth_each {
    my $self = $_[0];
    my $name = $self->name;
    $self->store->dbh->prepare("select data from $name");
}

sub _build_sth_delete {
    my $self = $_[0];
    my $name = $self->name;
    $self->store->dbh->prepare("delete from $name where id = ?");
}

sub _build_sth_delete_all {
    my $self = $_[0];
    my $name = $self->name;
    $self->store->dbh->prepare("delete from $name");
}

sub _build_dbh_add_sqlite {
    my $self = $_[0];
    my $name = $self->name;
    my $sth  = $self->store->dbh->prepare("insert or replace into $name values(?,?)");
    sub {
        $sth->execute($_[1], $_[2]);
    };
}

sub _build_dbh_add_mysql {
    my $self = $_[0];
    my $name = $self->name;
    my $sth  = $self->store->dbh->prepare("insert into $name values(?,?) on duplicate key update data = ?");
    sub {
        $sth->execute($_[1], $_[2], $_[2]);
    };
}

sub _build_dbh_add_generic {
    my $self = $_[0];
    my $name = $self->name;
    my $sth_update = $self->store->dbh->prepare("update $name set data = ? where id = ?");
    my $sth_insert = $self->store->dbh->prepare("insert into $name values(?,?) where not exists (select 1 from $name where id = ?)");
    sub {
        $sth_update->execute($_[2], $_[1]);
        $sth_insert->execute($_[1], $_[2], $_[1]) unless $sth_update->rows;
    };
}

sub _build_dbh_add {
    my $self = $_[0];
    given ($self->store->dbh->{Driver}{Name}) {
        when (/sqlite/i) { return $self->_build_dbh_add_sqlite }
        when (/mysql/i)  { return $self->_build_dbh_add_mysql }
        default          { return $self->_build_dbh_add_generic }
    }
}

sub get {
    my ($self, $id) = @_;
    my $row = $self->store->dbh->selectrow_arrayref($self->_sth_get, {}, $id) || return;
    decode_json($row->[0]);
}

sub add {
    my ($self, $data) = @_;
    $self->_dbh_add->($self, $data->{_id}, encode_json($data));
}

sub delete {
    my ($self, $id) = @_;
    $self->_sth_delete->execute($id);
}

sub delete_all {
    my ($self) = @_;
    $self->_sth_delete_all->execute;
}

sub generator {
    my ($self) = @_;
    sub {
        state $sth;
        state $row;
        unless ($sth) {
            $sth = $self->_build_sth_each;
            $sth->execute;
        }
        if ($row = $sth->fetchrow_arrayref) {
            return decode_json($row->[0]);
        }
        return;
    };
}

1;
