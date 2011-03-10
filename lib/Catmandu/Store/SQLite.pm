package Catmandu::Store::SQLite;
use DBI;
use Data::UUID;
use JSON ();
use Catmandu::Class qw(path);
use parent qw(
    Catmandu::Modifiable
    Catmandu::Pluggable
);

my $sql_create_table = "create table if not exists objects(id text primary key, data text not null)";
my $sql_st_load   = "select data from objects where id = ?";
my $sql_st_each   = "select data from objects";
my $sql_st_save   = "insert or replace into objects values(?,?)";
my $sql_st_delete = "delete from objects where id = ?";

sub plugin_namespace { 'Catmandu::Store::Plugin' }

sub build {
    my ($self, $args) = @_;
    $self->{path} = $args->{path} || confess("Attribute path is required");
}

sub dbh {
    my $self = $_[0];
    $self->{dbh} ||= do {
        my $dbh = DBI->connect("dbi:SQLite:dbname=".$self->path, "", "");
        $dbh->{sqlite_unicode} = 1;
        $dbh->do($sql_create_table) or confess $dbh->errstr;
        $dbh;
    };
}

sub sth_load   { $_[0]->dbh->prepare($sql_st_load) }
sub sth_each   { $_[0]->dbh->prepare($sql_st_each) }
sub sth_save   { $_[0]->dbh->prepare($sql_st_save) }
sub sth_delete { $_[0]->dbh->prepare($sql_st_delete) }

sub load {
    my ($self, $id) = @_;
    $id = $id->{_id} if ref $id eq 'HASH';
    $id or confess "_id missing";
    my $row = $self->dbh->selectrow_arrayref($self->sth_load, {}, $id) or return;
    JSON::decode_json($row->[0]);
}

sub each {
    my ($self, $sub) = @_;
    my $sth = $self->sth_each;
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
    my $id = $obj->{_id} ||= Data::UUID->new->create_str;
    $self->sth_save->execute($id, JSON::encode_json($obj));
    $obj;
}

sub delete {
    my ($self, $id) = @_;
    $id = $id->{_id} if ref $id eq 'HASH';
    $id or confess "_id missing";
    $self->sth_delete->execute($id);
}

sub transaction {
    my ($self, $sub) = @_;

    return $sub->() if $self->{in_transaction};

    my $dbh = $self->dbh;
    my @res;

    eval {
        $self->{in_transaction} = 1;
        $dbh->begin_work;
        @res = $sub->();
        $dbh->commit;
        $self->{in_transaction} = 0;
        1;
    } or do {
        my $error = $@;
        $dbh->rollback;
        $self->{in_transaction} = 0;
        confess $error;
    };

    @res;
}

1;
