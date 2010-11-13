use HTTP::Request::Common;
use Test::More tests => 7;
use Plack::Test;

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

package main;

my $app = T::App->as_psgi_app;

test_psgi $app, sub {
    my $sub = shift;
    my $res;

    $res = $sub->(GET "/runhelper");
    is $res->code, 200;
    is $res->content, "body";

    $res = $sub->(GET "/runsub");
    is $res->code, 200;
    is $res->content, "body";

    $res = $sub->(GET "/404");
    is $res->code, 404;
};

done_testing;

