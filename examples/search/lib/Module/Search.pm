package Module::Search;

use Catmandu::App;
use Plack::Util;

get '/' => sub {
    my $self  = shift;
    $self->print_template('search');
};

get '/login' => sub {
    my $self  = shift;

    $self->print_template('login');
};

post '/login' => sub {
    my $self  = shift;

    $self->auth->authenticate;

    $self->redirect('/');
};

get '/logout' => sub {
    my $self = shift;

    $self->auth->clear_user;

    $self->redirect('/');
};

get '/view' => sub {
    my $self  = shift;
    my $id    = $self->req->param('id');

    my $obj = $self->store->load($id);

    $self->print_template('view' , { id => $id , res => $obj});
};

get '/search' => sub {
    my $self  = shift;
    my $q     = $self->req->param('q');
    my $start = $self->req->param('start') || 0;
    my $num   = $self->req->param('num') || 10;

    my ($results, $hits) = $self->index->search($q, start => $start , limit => $num, reify => $self->store);

    my $next = ($start + $num < $hits) ? $start + $num : -1;
    my $prev = ($start - $num >= 0) ? $start - $num : -1; 
    my $end  = ($start + $num < $hits) ? $start + $num : $hits;

    my ($spage,$curr,$epage) = $self->pages($start, $num, $hits); 

    $self->print_template('search' , { 
                            hits => $hits , 
                            results => $results , 
                            next  => $next , 
                            prev  => $prev ,
                            start => $start + 1,
                            end   => $end ,
                            num   => $num ,
                            spage => $spage ,
                            curr  => $curr ,
                            epage => $epage ,
                        });
};

# Authentication magic
enable 'Session';
enable 'Catmandu::Auth' ,
        failure_app => sub { [301, [ 'Location' => '/login' ] , []] },
        strategies => {
            simple => {
                auth => sub {
                    my ($username,$password) = @_;
                    if ($username eq 'phochste') {
                        1;
                    }
                    else {
                        0; 
                    }
                } ,
                load_user => sub {
                    my ($username) = @_;
                    return {_id => 1 , name => uc $username};
                }
            }
        },
        into_session => sub { $_[0]->{_id} },
        from_session => sub { {_id => $_[0] , name => 'xx'} };

sub auth {
    my $self = shift;

    $self->env->{'catmandu.auth'};
}

sub pages {
    my $self = shift;
    my ($start, $num, $hits) = @_;

    use POSIX qw/ceil floor/;

    my $curr = floor($start/$num);
    my $last = ceil($hits/$num);

    my $spage = $curr - 10 > 0 ? $curr - 10 : 1;
    my $epage = $curr + 10 < $last ? $curr + 10 : $last;

    ($spage,$curr,$epage);
}

sub store {
    my $self = shift;

    my $class = Plack::Util::load_class(Catmandu->conf->{db}->{class});
    my $args  = Catmandu->conf->{db}->{args};

    $self->stash->{store} ||= $class->new(%$args);
}

sub index {
    my $self = shift;

    my $class = Plack::Util::load_class(Catmandu->conf->{index}->{class});
    my $args  = Catmandu->conf->{index}->{args};

    $self->stash->{index} ||= $class->new(%$args);
}

__PACKAGE__->meta->make_immutable;
no Catmandu::App;
__PACKAGE__;

