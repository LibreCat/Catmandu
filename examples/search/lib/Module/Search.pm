package Module::Search;
use Moose;
use base qw(Catmandu::App);
use Catmandu;
use Catmandu::Util;
use POSIX qw(ceil floor);

has indexer => (
    is => 'ro',
    does => 'Catmandu::Indexer',
    default => sub {
        my $self = shift;
        my $class = Catmandu::Util::load_class(Catmandu->conf->{index}->{class});
        my $args = Catmandu->conf->{index}->{args};
        $class->new($args);
    },
);

has store => (
    is => 'ro',
    does => 'Catmandu::Store',
    default => sub {
        my $self = shift;
        my $class = Catmandu::Util::load_class(Catmandu->conf->{db}->{class});
        my $args = Catmandu->conf->{db}->{args};
        $class->new($args);
    },
);

sub BUILD {
    my $self = shift;

    $self->locale_param('lang');

    $self->middleware('Session');

    $self->middleware('Catmandu::Auth' ,
        failure_app => sub { [301, [ 'Location' => '/login' ] , []] },
        strategies => {
            simple => {
                auth => sub {
                    my ($username, $password) = @_;
                    $username eq 'phochste' ? 1 : 0;
                },
                load_user => sub {
                    my ($username) = @_;
                    {_id => 1 , name => uc $username};
                }
            }
        },
        into_session => sub { $_[0]->{_id} },
        from_session => sub { {_id => $_[0] , name => 'xx'} }
    );
}

sub home : GET {
    my ($self, $web) = @_;

    $web->print_template('search');
}

sub login : GET {
    my ($self, $web) = @_;

    $web->print_template('login');
}

sub authenticate : POST("/login") {
    my ($self, $web) = @_;

    $web->env->{'catmandu.auth'}->authenticate;

    $web->redirect('/');
}

sub logout : R {
    my ($self, $web) = @_;

    $web->env->{'catmandu.auth'}->clear_user;

    $web->redirect('/');
}


sub view : GET {
    my ($self, $web) = @_;

    my $id  = $self->req->param('id');

    my $obj = $self->store->load($id);

    $web->print_template('view', { id => $id , res => $obj });
};

get '/search' => sub {
    my ($self, $web) = @_;

    my $q     = $web->req->param('q');
    my $start = $web->req->param('start') || 0;
    my $num   = $web->req->param('num')   || 10;

    my ($results, $hits, $error) = $self->indexer->search($q, start => $start, limit => $num, reify => $self->store);

    my $next = ($start + $num < $hits) ? $start + $num : -1;
    my $prev = ($start - $num >= 0) ? $start - $num : -1;
    my $end  = ($start + $num < $hits) ? $start + $num : $hits;

    my ($spage, $curr, $epage) = $self->paginate($start, $num, $hits); 

    $web->print_template('search', {
        error   => $error,
        hits    => $hits,
        results => $results,
        next    => $next,
        prev    => $prev,
        start   => $start + 1,
        end     => $end,
        num     => $num,
        spage   => $spage,
        curr    => $curr,
        epage   => $epage,
    });
};

sub paginate {
    my ($self, $start, $num, $hits) = @_;

    my $curr = floor($start/$num);
    my $last = ceil($hits/$num);

    my $spage = $curr - 10 > 0 ? $curr - 10 : 1;
    my $epage = $curr + 10 < $last ? $curr + 10 : $last;

    ($spage,$curr,$epage);
}

sub conf {
    Catmandu->conf;
}

__PACKAGE__->meta->make_immutable;

no Moose;
no POSIX;

1;

