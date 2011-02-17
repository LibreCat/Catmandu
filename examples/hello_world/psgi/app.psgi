use Catmandu::App;

Catmandu::App
    ->new
    ->GET('/', to => sub { shift->print_template('index') })
    ->as_psgi_app;

