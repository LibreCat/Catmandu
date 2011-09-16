package Catmandu::Store::DBI;
use Catmandu::Sane;
use parent qw(Catmandu::Store);
use Catmandu::Util qw(opts);
use DBI;
use Catmandu::Object
    dsn      => 'r',
    username => { default => sub { '' } },
    password => { default => sub { '' } },
    dbh      => { default => '_build_dbh' };

sub _build_args {
    my ($self, $dsn, @args) = @_;
    my $args = opts @args;
    $args->{dsn} = $dsn;
    $args;
}

sub _build_dbh {
    my $self = $_[0];
    DBI->connect($self->dsn, $self->username, $self->password, {
        AutoCommit => 1,
        RaiseError => 1,
    });
}

sub transaction {
    my ($self, $sub) = @_;

    my $dbh = $self->dbh;

    if (! $dbh->{AutoCommit}) {
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

sub DESTROY {
    $_[0]->dbh->disconnect;
}

package Catmandu::Store::DBI::Collection;
use Catmandu::Sane;
use parent qw(Catmandu::Collection);
use Catmandu::Util qw(get_id);
use JSON;
use Catmandu::Object
    _sth_get    => { default => '_build_sth_get' },
    _sth_each   => { default => '_build_sth_each' },
    _sth_delete => { default => '_build_sth_delete' },
    _dbh_add    => { default => '_build_dbh_add' };

sub _build {
    my ($self, $args) = @_;
    $self->SUPER::_build($args);
    my $name = $self->name;
    $self->store->dbh->do("create table if not exists $name(id varchar(255) not null primary key, data text not null)");
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

sub _get {
    my ($self, $id) = @_;
    my $row = $self->store->dbh->selectrow_arrayref($self->_sth_get, {}, $id) || return;
    JSON::decode_json($row->[0]);
}

sub _add {
    my ($self, $obj) = @_;
    $self->_dbh_add->($self, get_id($obj), JSON::encode_json($obj));
    $obj;
}

sub _delete {
    my ($self, $id) = @_;
    $self->_sth_delete->execute($id);
    return;
}

1;
