package Module::Hello;

use Catmandu::App;

get '/' => sub {
    my $self = shift;
    $self->print_template('index');
};

__PACKAGE__->meta->make_immutable;
no Catmandu::App;
__PACKAGE__;
