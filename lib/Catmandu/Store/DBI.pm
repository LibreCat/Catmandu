package Catmandu::Store::DBI;
use Catmandu::Sane;
use parent qw(Catmandu::Store);
use Catmandu::Util qw(quack get_id opts);
use JSON qw(encode_json decode_json);
use DBI;
use Catmandu::Object
    dsn => 'r',
    username => { default => sub { "" } },
    password => { default => sub { "" } },
    table    => { default => sub {'objects'} },
    dbh         => { default => '_build_dbh' },
    _sth_get    => { default => '_build_sth_get' },
    _sth_each   => { default => '_build_sth_each' },
    _sth_delete => { default => '_build_sth_delete' },
    _dbh_add    => { default => '_build_dbh_add' };

sub _build_args {
    my ($self, $dsn, @args) = @_;
    my $args = opts(@args);
    $args->{dsn} = $dsn;
    $args;
}

sub _build {
    my ($self, $args) = @_;

    $self->{dsn}      = $args->{dsn};
    $self->{username} = $args->{username};
    $self->{password} = $args->{password};
    $self->{table}    = $args->{table};

    my $table = $self->table;

    $self->dbh->do("create table if not exists $table(id varchar(255) not null primary key, data text not null)");

    $self->SUPER::_build($args);
}

sub _build_dbh {
    my $self = $_[0];
    DBI->connect($self->dsn, $self->username, $self->password, {
        AutoCommit => 1,
        RaiseError => 1,
    });
}

sub _build_sth_get {
    my $self = $_[0];
    my $table = $self->table;
    $self->dbh->prepare("select data from $table where id = ?");
}

sub _build_sth_each {
    my $self = $_[0];
    my $table = $self->table;
    $self->dbh->prepare("select data from $table");
}

sub _build_sth_delete {
    my $self = $_[0];
    my $table = $self->table;
    $self->dbh->prepare("delete from $table where id = ?");
}

sub _build_dbh_add_sqlite {
    my $self = $_[0];
    my $table = $self->table;
    my $sth = $self->dbh->prepare("insert or replace into $table values(?,?)");
    sub {
        $sth->execute($_[1], $_[2]);
    };
}

sub _build_dbh_add_mysql {
    my $self = $_[0];
    my $table = $self->table;
    my $sth = $self->dbh->prepare("insert into $table values(?,?) on duplicate key update data = ?");
    sub {
        $sth->execute($_[1], $_[2], $_[2]);
    };
}

sub _build_dbh_add_generic {
    my $self = $_[0];
    my $table = $self->table;
    my $sth_update = $self->dbh->prepare("update $table set data = ? where id = ?");
    my $sth_insert = $self->dbh->prepare("insert into $table values(?,?) where not exists (select 1 from $table where id = ?)");
    sub {
        $sth_update->execute($_[2], $_[1]);
        $sth_insert->execute($_[1], $_[2], $_[1]) unless $sth_update->rows;
    };
}

sub _build_dbh_add {
    my $self = $_[0];
    given ($self->type) {
        when (/sqlite/i) { return $self->_build_dbh_add_sqlite }
        when (/mysql/i)  { return $self->_build_dbh_add_mysql }
        default          { return $self->_build_dbh_add_generic }
    }
}

sub type {
    $_[0]->dbh->{Driver}{Name};
}

sub each {
    my ($self, $sub) = @_;
    my $sth = $self->_sth_each;
    $sth->execute;
    my $n = 0;
    while (my $row = $sth->fetchrow_arrayref) {
        $sub->(decode_json($row->[0]));
        $n++;
    }
    $n;
}

sub _get {
    my ($self, $id) = @_;
    my $row = $self->dbh->selectrow_arrayref($self->_sth_get, {}, $id) || return;
    decode_json($row->[0]);
}

sub _add {
    my ($self, $obj) = @_;
    $self->_dbh_add->($self, get_id($obj), encode_json($obj));
    $obj;
}

sub _delete {
    my ($self, $id) = @_;
    $self->_sth_delete->execute($id);
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
    my ($self) = @_;
    $self->dbh->disconnect;
}

1;
