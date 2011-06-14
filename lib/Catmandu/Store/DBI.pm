package Catmandu::Store::DBI;
use Catmandu::Sane;
use Catmandu::Util qw(quack ensure_id assert_id);
use JSON qw(to_json from_json);
use DBI;
use Catmandu::Object
    dsn => 'r',
    username => { default => sub { "" } },
    password => { default => sub { "" } },
    table => { default => 'objects' },
    transaction_running => { default => sub { 0 } },
    dbh         => { default => '_build_dbh' },
    _sth_get    => { default => '_build_sth_get' },
    _sth_each   => { default => '_build_sth_each' },
    _sth_delete => { default => '_build_sth_delete' },
    _dbh_add    => { default => '_build_dbh_add' };

sub _build_args {
    my ($self, $dsn, @args) = @_;
    my $args = $self->SUPER::_build_args(@args);
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

    $self->dbh->do("set names 'utf8'");
    $self->dbh->do("set collation 'utf8_general_ci'");
    $self->dbh->do("set character set 'utf8'");
    $self->dbh->do("create table if not exists $table(id text not null primary key, data text not null)");
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
        when (/sqlite/) { $self->_build_dbh_add_sqlite }
        when (/mysql/)  { $self->_build_dbh_add_mysql }
        default         { $self->_build_dbh_add_generic }
    }
}

sub _build_dbh {
    DBI->connect($_[0]->dsn, $_[0]->username, $_[0]->password, {AutoCommit => 0, RaiseError => 1});
}

sub type {
    $_[0]->dbh->{Driver}{Name};
}

sub get {
    my ($self, $id) = @_;
    my $row = $self->dbh->selectrow_arrayref($self->_sth_get, {}, assert_id($id)) || return;
    from_json($row->[0]);
}

sub each {
    my ($self, $sub) = @_;
    my $sth = $self->_sth_each;
    $sth->execute;
    my $n = 0;
    while (my $row = $sth->fetchrow_arrayref) {
        $sub->(from_json($row->[0]));
        $n++;
    }
    $n;
}

sub _add_obj {
    my ($self, $obj) = @_;
    my $id = ensure_id($obj);
    $self->_dbh_add->($self, $id, to_json($obj));
    $obj;
}

sub add {
    my ($self, $obj) = @_;
    if (quack $obj, 'each') {
        $obj->each(sub { $self->_add_obj($_[0]) });
    } else {
        $self->_add_obj($obj);
    }
}

sub delete {
    my ($self, $id) = @_;
    $self->_sth_delete->execute(assert_id($id));
}

sub transaction {
    my ($self, $work) = @_;

    return $work->() if $self->{transaction_running};

    my $dbh = $self->dbh;
    my @res;

    eval {
        $self->{transaction_running} = 1;
        $dbh->begin_work;
        @res = $work->();
        $dbh->commit;
        $self->{transaction_running} = 0;
        1;
    } or do {
        my $error = $@;
        eval { $dbh->rollback };
        $self->{transaction_running} = 0;
        confess $error;
    };

    @res;
}

1;
