package Catmandu::Index::ElasticSearch;
use Catmandu::Sane;
use Catmandu::Util qw(quack assert_id);
use ElasticSearch;
use Catmandu::Object 
    index_name  => 'r',
    type        => 'r',
    mapping     => 'r',
    es          => { default => '_build_es' },
    buffer_size => { default => sub { 500 } },
    _buffer     => { default => sub { [] },
                     clearer => 1 };

sub default_es_args {
    { servers => "127.0.0.1:9200" };
}

sub allowed_es_args {
    state $allowed_es_args = [qw(
        transport
        servers
        trace_calls
        timeout
        max_requests
        no_refresh
    )];
}

sub _build {
    my ($self, $args) = @_;
    $self->{index_name} = delete $args->{index};
    $self->{type} = delete $args->{type};
    $self->{mapping} = delete $args->{mapping};
    $self->{buffer_size} = delete $args->{buffer_size};
    $self->{es} = delete $args->{es};
    if (! $self->{es}) {
        $self->{es_args} = $self->default_es_args;
        my $keys = $self->allowed_es_args;
        for my $key (@$keys) {
            $self->{es_args}{$key} = $args->{$key} if exists $args->{$key};
        }
    }
    if (my $mapping = $self->mapping) {
        $mapping->{index} = $self->index_name;
        $mapping->{type}  = $self->type;
        $self->es->put_mapping($mapping);
    }
}

sub _build_es {
    ElasticSearch->new($_[0]->{es_args});
}

sub _add {
    my ($self, $obj) = @_;
    assert_id($obj);

    my $buffer = $self->_buffer;

    push @$buffer, {
        index => $self->index_name,
        type  => $self->type,
        id    => $obj->{_id},
        data  => $obj,
    };

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

    $query = {query_string => {query => $query}} unless ref $query;

    $opts{index} = $self->index_name;
    $opts{type}  = $self->type;
    $opts{query} = $query;
    $opts{from}  = delete $opts{skip};

    my $store = delete $opts{reify};

    my $res = $self->es->search(%opts);

    my $hits = $res->{hits}{hits};
    my $total_hits = $res->{hits}{total};

    if ($store) {
        $hits = [ map { $store->get($_->{_id}) } @$hits ];
    } else {
        $hits = [ map { $_->{_source} } @$hits ];
    }

    return $hits,
           $total_hits;
}

sub delete {
    my ($self, $id) = @_;
    $self->es->delete(
        index => $self->index_name,
        type => $self->type,
        id => assert_id($id),
    );
}

sub delete_where {
    my ($self, $query) = @_;
    $query = {query_string => {query => $query}} unless ref $query;
    $self->es->delete_by_query(
        index => $self->index_name,
        type => $self->type,
        query => $query,
    );
    $self->es->optimize_index(
        index => $self->index_name,
        only_deletes => 1,
    );
}

sub delete_all {
    my ($self) = @_;
    $self->es->delete_index(
        index => $self->index_name,
        ignore_missing => 1,
    );
}

sub commit {
    my ($self) = @_;

    my $res = $self->es->bulk_index($self->_buffer)->{results};
    for my $r (@$res) {
        if (my $e = $r->{index}{error}) {
            $self->_clear_buffer; #TODO shouldn't die; log buffer contents
            confess $e;
        }
    }
    $self->_clear_buffer;
    $self->es->optimize_index(index => $self->index_name);
}

1;
