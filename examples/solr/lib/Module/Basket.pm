package Module::Basket;
use Moose;
BEGIN { extends 'Catmandu::App' };
use Catmandu;
use Catmandu::Util;
use JSON;

with 'Catmandu::App::Plugin::Locale';

before run => sub {
    $_[0]->session->{basket} ||= {};
};

sub BUILD {
    my $self = shift;
    
    $self->GET('/list', run => sub {
        my $self  = shift;

        $self->res->content_type('text/plain');

        my $objs = $self->session->{basket};
        $objs->{count} = int(keys %$objs);

        $self->print(
                to_json($objs)
                );
    });

    $self->POST('/add', run => sub {
        my $self  = shift;
        my $id    = $self->req->param('id');

        Catmandu->logger->debug("add $id");  

        $self->session->{basket}->{$id} = 1;
    });

    $self->POST('/delete', run => sub {
        my $self  = shift;
        my $id    = $self->req->param('id');

        Catmandu->logger->debug("delete $id");

        delete $self->session->{basket}->{$id};
    });

    $self->POST('/clear', run => sub {
        my $self  = shift;

        Catmandu->logger->debug("clear");

        $self->session->{basket} = {};
    });
}

__PACKAGE__->meta->make_immutable;
no Catmandu::App;
__PACKAGE__;

