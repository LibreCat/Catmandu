use Plack::Builder;
use Module::Search;
use Module::Basket;

builder {

    mount "/" => builder {
        enable "Plack::Middleware::Static" ,
            path => qr{^/(images|js|css)/} , root => './htdocs/';
        Module::Search->as_psgi_app;
    };

    mount "/basket" => builder {
        enable "Plack::Middleware::Session";
        Module::Basket->as_psgi_app;
    };
};
