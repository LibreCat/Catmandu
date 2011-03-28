package Hepcat::Authn;
use Dancer ':syntax';

our $VERSION = '0.1';

before sub {
    if (!session->{user} && request->path_info !~ m{^/login}) {
        var original_path => request->path_info;
        request->path_info('/login');
    }
};

get '/login' => sub {
    template 'login', {original_path => vars->{original_path}};
};

post '/login' => sub {
    if (params->{user} && params->{pass} eq 'secret') {
        session user => params->{user};
        redirect params->{original_path} || '/';
    } else {
        redirect '/login?failed=1';
    }
};

true;
