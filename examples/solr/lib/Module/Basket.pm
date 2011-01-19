package Module::Basket;

use Catmandu::App;
use JSON;

get '/list' => sub {
    my $self  = shift;

    $self->res->content_type('text/plain');

    my $objs = $self->session->{basket};
    my $objs->{count} = int(keys %$objs);

    $self->print(
            to_json($objs)
            );
};

post '/add' => sub {
    my $self  = shift;
    my $id    = $self->req->param('id');

    Catmandu->logger->debug("add $id");  

    $self->session->{basket}->{$id} = 1;
};

post '/delete' => sub {
    my $self  = shift;
    my $id    = $self->req->param('id');

    Catmandu->logger->debug("delete $id");  

    delete $self->session->{basket}->{$id};
};

post '/clear' => sub {
    my $self  = shift;

    Catmandu->logger->debug("clear");  

    $self->session->{basket} = {};
};

sub BUILD {
    my $self = shift;
    
    unless (defined $self->session && defined $self->session->{basket}) {
        $self->session->{basket} = {};
    }
}

__PACKAGE__->meta->make_immutable;
no Catmandu::App;
__PACKAGE__;

