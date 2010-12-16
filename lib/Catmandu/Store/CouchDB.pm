package Catmandu::Store::CouchDB;

use namespace::autoclean;
use 5.010;
use Moose;
use AnyEvent::CouchDB;
use Catmandu::Err;
use Try::Tiny;

with qw(Catmandu::Store);

has url     => (is => 'ro', isa => 'Str', required => 1, builder => '_build_url');
has name    => (is => 'ro', isa => 'Str', required => 1);
has couch   => (is => 'ro', isa => 'Object', required => 1, lazy => 1, builder => '_build_couch');
has db      => (is => 'ro', isa => 'Object', required => 1, lazy => 1, builder => '_build_db');

sub _build_url {
    'http://localhost:5984/';
}

sub _build_couch {
    my $self = shift; AnyEvent::CouchDB->new($self->url);
}

sub _build_db {
    my $self = shift;
    my $name = $self->name;
    my $db = $self->couch->db($name);
    my $db_names = $self->couch->all_dbs->recv;
    if (! grep /^$name$/, @$db_names) {
        $db->create->recv;
    }
    $db;
}

sub load {
    my ($self, $id) = @_;
    my $obj = try {
        $self->db->open_doc($id)->recv;
    } catch {
        if (ref $_ eq 'ARRAY') {
            return if $_->[1]->{reason} eq 'missing';
            confess(Catmandu::HTTPErr->new($_->[0]->{Status}, headers => $_->[0], body => $_->[1]));
        } else {
            confess($_);
        }
    };
    if ($self->id_field ne '_id') {
        $obj->{$self->id_field} = delete $obj->{_id};
    }
    $obj;
}

sub each {
    my ($self, $sub) = @_;
    my $id_field = $self->id_field;
    my $rekey_id_field = $id_field ne '_id';
    my $db = $self->db;
    my $startkey = "";
    my $limit = 20;
    my $n;
    for (;;) {
        my $response = try {
            $db->all_docs({
                include_docs => 1,
                limit        => $limit,
                startkey     => $startkey,
                skip         => $startkey ? 1 : 0,
            })->recv;
        } catch {
            if (ref $_ eq 'ARRAY') {
                confess(Catmandu::HTTPErr->new($_->[0]->{Status}, headers => $_->[0], body => $_->[1]));
            } else {
                confess($_);
            }
        };

        my $offset = $response->{offset};
        my $total  = $response->{total_rows};
        $n //= $total || last;

        my $rows = $response->{rows};
        for my $row (@$rows) {
            my $obj = $row->{doc};
            $obj->{$id_field} = delete $obj->{_id} if $rekey_id_field;
            $sub->($obj);
        }

        last if $offset + $limit >= $total;

        $startkey = $rows->[-1]->{id};
    }
    $n;
}

sub save {
    my ($self, $obj) = @_;

    my $id_field = $self->id_field;

    if ($id_field ne '_id' and my $id = delete $obj->{$id_field}) {
        $obj->{_id} = $id;
    }

    try {
        $self->db->save_doc($obj)->recv;
    } catch {
        if (ref $_ eq 'ARRAY') {
            confess(Catmandu::HTTPErr->new($_->[0]->{Status}, headers => $_->[0], body => $_->[1]));
        } else {
            confess($_);
        }
    };

    if ($id_field ne '_id') {
        $obj->{$id_field} = delete $obj->{_id};
    }

    $obj;
}

sub delete {
    my ($self, $obj) = @_;
    my $id_field = $self->id_field;
    if (ref $obj) {
        if ($id_field ne '_id') {
            $obj->{_id} = delete $obj->{$id_field};
        }
        $obj->{_id} or confess "Missing $id_field";
    } else {
        $obj or confess "Missing $id_field";
        $obj = { _id => $obj };
    }
    try {
        $self->db->remove_doc($obj)->recv;
    } catch {
        if (ref $_ eq 'ARRAY') {
            return if $_->[1]->{reason} eq 'missing';
            confess(Catmandu::HTTPErr->new($_->[0]->{Status}, headers => $_->[0], body => $_->[1]));
        } else {
            confess($_);
        }
    };
}

__PACKAGE__->meta->make_immutable;

1;

