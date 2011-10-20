package Catmandu::Index::ElasticSearch;
use Catmandu::Sane;
use Catmandu::Util qw(quacks assert_id);
use ElasticSearch;
use CQL::ElasticSearch;
use Catmandu::Hits;
use Catmandu::Object 
    index_name  => 'r',
    type => 'r',
    index_template => 'r',
    es_args => 'r',
    es => { default => '_build_es' },
    buffer_size => { default => sub { 100 } },
    _buffer => { default => sub { [] }, clearer => 1 };

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
    $self->{index_template} = delete $args->{index_template};
    $self->{buffer_size} = delete $args->{buffer_size};
    $self->{es_args} = $self->default_es_args;
    my $keys = $self->allowed_es_args;
    for my $key (@$keys) {
        $self->{es_args}{$key} = $args->{$key} if exists $args->{$key};
    }

    if (my $tmpl = $self->index_template) {
        $self->es->create_index_template(
            name     => $self->index_name,
            template => $self->index_name,
            %$tmpl,
        );
    }
}

sub _build_es {
    ElasticSearch->new($_[0]->es_args);
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
    if (quacks $obj, 'each') {
        $obj->each(sub { $self->_add($_[0]) });
    } else {
        $self->_add($obj);
    }
}

sub search {
    my ($self, $query, %opts) = @_;

    $query = {query => {query_string => {query => $query}}} unless ref $query;
    $query->{index} = $self->index_name;
    $query->{type} = $self->type;
    $query->{size} //= $opts{limit} // 50;
    $query->{from} //= $opts{start} // 0;

    my $res = $self->es->search(%$query);

    my $hits = $res->{hits}{hits};

    my $hits_obj = Catmandu::Hits->new({
        limit => $query->{size},
        start => $query->{from},
        total => $res->{hits}{total},
    });

    if ($res->{facets}) {
        $hits_obj->{facets} = $res->{facets};
    }

    if (my $store = $opts{reify}) {
        $hits_obj->{hits} = [ map { $store->get($_->{_id}) } @$hits ];
    } else {
        $hits_obj->{hits} = [ map { 
            if (my $hl = $_->{highlight}) {
                $hits_obj->{highlight}{$_->{_id}} = $hl;
            }
            $_->{_source};
        } @$hits ];
    }

    $hits_obj;
}

sub cql_search {
    my ($self, $query, %opts) = @_;
    $self->search({query => CQL::ElasticSearch->parse($query)}, %opts);
}

sub delete {
    my ($self, $id) = @_;
    $self->es->delete(
        index => $self->index_name,
        type => $self->type,
        id => assert_id($id),
    );
    return;
}

sub delete_where {
    my ($self, $query) = @_;
    $query = {query => {query_string => {query => $query}}} unless ref $query;
    $query->{index} = $self->index_name;
    $query->{type} = $self->type;
    $self->es->delete_by_query(%$query);
    return;
}

sub delete_all {
    my ($self) = @_;
    $self->es->delete_index(
        index => $self->index_name,
        ignore_missing => 1,
    );
    return;
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
