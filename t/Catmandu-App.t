use HTTP::Request::Common;
use Path::Class;
use Test::More tests => 7;
use Plack::Test;
use Catmandu;

Catmandu->initialize(env => 'test');

BEGIN { use_ok 'Catmandu::App'; }
require_ok 'Catmandu::App';

my $test_app = Catmandu::App->new;

$test_app->route('/anonymous', to => sub {
    my ($app, $web) = @_;
    $web->print('anonymous');
});

$test_app->route('/named', as => 'named', to => sub {
    my ($app, $web) = @_;
    $web->print('named');
});

test_psgi $test_app->psgi_app, sub {
    my $sub = shift;
    my $res;

    $res = $sub->(GET "/anonymous");
    is $res->code, 200;
    is $res->content, "anonymous";

    $res = $sub->(GET "/named");
    is $res->code, 200;
    is $res->content, "named";

    $res = $sub->(GET "/404");
    is $res->code, 404;
};

done_testing;

