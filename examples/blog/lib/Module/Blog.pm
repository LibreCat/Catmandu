package Module::Blog;

use Catmandu::App;
use Catmandu::Store::Simple;

get '/' => sub {
    my $self  = shift;
    $self->print_template('blog', { blog => $self->list} );
};

post '/' => sub {
    my $self  = shift;
    my $msg   = $self->request->param('msg');
    
    my $date = localtime time;

    $self->store->save({
            date => $date , 
            msg  => $msg ,
        });


    $self->print_template('blog', { blog => $self->list } );
};

sub store {
    my $self = shift;
    $self->stash->{store} ||=
        Catmandu::Store::Simple->new(
          file => Catmandu->conf->{db}->{blog}
        );
}

sub list {
    my $self = shift;
    my @list = ();

    $self->store->each(sub {
        my $obj = shift;
        push(@list, $obj);
    });
   
    [ reverse @list ];
}

__PACKAGE__->meta->make_immutable;
no Catmandu::App;
__PACKAGE__;

