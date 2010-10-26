use Test::More;
use Plack::Test;
use HTTP::Request::Common;

BEGIN { use_ok 'Catmandu::App'; }
require_ok 'Catmandu::App';

package T::App;

use Catmandu::App;

sub helper {
    shift->print('body');
}

get '/runhelper' => 'helper';

get '/runsub' => sub {
    shift->helper;
};

__PACKAGE__->on_get('/echo/:text', sub {
    my $self = shift;
    $self->response->content_type('text/plain');
    $self->print($self->param('text'));
});

package main;

my $app = T::App->as_psgi_app;

test_psgi $app, sub {
    my $cb = shift;
    my $res;

    $res = $cb->(GET "/runhelper");
    is $res->code, 200;
    is $res->content, "body";

    $res = $cb->(GET "/runsub");
    is $res->code, 200;
    is $res->content, "body";

    $res = $cb->(GET "/404");
    is $res->code, 404;
};

done_testing;

