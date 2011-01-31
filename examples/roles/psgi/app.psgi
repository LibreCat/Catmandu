use Plack::Builder;
use Module::Roles;

builder {
    mount "/" => builder {
        enable "Plack::Middleware::Static" ,
            path => qr{^/(images|js|css)/} , root => './htdocs/';
        Module::Roles->as_psgi_app;
    };
};
