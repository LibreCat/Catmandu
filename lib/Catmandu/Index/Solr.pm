package Catmandu::Index::Solr;
use Catmandu::Sane;
use Catmandu::Util qw(quack assert_id);
use WebService::Solr;
use Catmandu::Object
    url         => { default => sub { 'http://localhost:8983/solr' } },
    solr        => { default => '_build_solr' },
    buffer_size => { default => sub { 100 } },
    _buffer     => { default => sub { [] },
                     clearer => 1 };

sub _build_solr {
    WebService::Solr->new($_[0]->url, {autocommit => 0 , default_params => { wt => 'json' }});
}

sub _add {
    my ($self, $obj) = @_;
    assert_id($obj);

    my $buffer = $self->_buffer;
    my @fields;

    for my $key (keys %$obj) {
        my $val = $obj->{$key} // next;

        if (ref $val) {
            foreach (@$val) {
                push @fields, WebService::Solr::Field->new($key => $_);
            }
        } else {
            push @fields, WebService::Solr::Field->new($key => $val);
        }
    }

    push @$buffer, WebService::Solr::Document->new(@fields);

    if (@$buffer == $self->buffer_size) {
        $self->commit;
    }

    $obj;
}

sub add {
    my ($self, $obj) = @_;
    if (quack $obj, 'each') {
        $obj->each(sub { $self->_add($_[0]) });
    } else {
        $self->_add($obj);
    }
}

sub search {
    my ($self, $query, %opts) = @_;

    my $skip = delete $opts{skip};
    my $size = delete $opts{size};
    my $store = delete $opts{reify};

    my $res = $self->solr->search($query, {start => $skip, rows => $size, %opts});

    my $hits       = $res->content->{response}->{docs};
    my $total_hits = $res->content->{response}->{numFound};

    if ($store) {
        $hits = [ map { $store->get($_->{_id}) } @$hits ];
    }

    return $hits,
           $total_hits;
}

sub delete {
    my ($self, $id) = @_;
    $id = assert_id($id);
    $self->solr->delete_by_query("_id:$id");
    return;
}

sub delete_where {
    my ($self, $query) = @_;
    $self->solr->delete_by_query($query);
    return;
}

sub delete_all {
    my ($self) = @_;
    $self->delete_where("*:*");
    return;
}

sub commit { # TODO optimize
    my ($self) = @_;

    eval {
        $self->solr->add($self->_buffer);
        $self->solr->commit;
        $self->_clear_buffer;
        1;
    } or do {
        my $error = $@;
        $self->_clear_buffer; #TODO shouldn't die; log buffer contents
        confess $error;
    };
}

1;
