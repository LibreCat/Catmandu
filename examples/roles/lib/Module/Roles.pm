package Module::Roles;

use Moose;
use base 'Catmandu::App';
use Catmandu::Store::Simple;

has store => (
    is => 'ro',
    lazy => 1,
    default => sub {
        Catmandu::Store::Simple->new(
            path => Catmandu->conf->{db}->{roles}
        );
    },
);

sub home :GET('/') {
    my $self  = shift;
    $self->print_template('roles', { roles => { $self->all_roles } });
};

sub roles :GET {
    my $self  = shift;
    my $query = $self->req->param('q');
    my %lib   = $self->all_roles;
    my @roles = grep {/^$query/} keys %lib;

    $self->print(join "\n" , sort @roles);
}

sub users :GET {
    my $self  = shift;
    my $query = $self->req->param('q');
    my @users = grep {/^$query/} map { $_->{name} } $self->all_users;

    $self->print(join "\n" , sort @users);
}

sub emails :GET {
    my $self  = shift;
    my $query = $self->req->param('q');
    my @emails = grep {/^$query/} map { $_->{email} } $self->all_users;

    $self->print(join "\n" , sort @emails);
}

sub del :R {
    my $self = shift;
    my $name = $self->req->param('name');
    my $role = $self->req->param('role');

    my $user = $self->find_roles($name);

    $user->{roles} = [ grep {$_ ne $role} @{$user->{roles}} ];

    $self->store->save($user);

    $self->redirect('/');
}

sub save_roles :POST('/') {
    my $self = shift;

    my $name  = $self->req->param('name');
    my $email = $self->req->param('email');
    my $roles = $self->req->param('roles');

    $name =~ s/(^\s+|\s+$)//;

    my $user = $self->find_roles($name);

    foreach my $role ( split(/\s*;\s*/,$roles)) {
        $role = lc $role;
        $role =~ s{^\s+}{};
        $role =~ s{\s+$}{};
        $role =~ s{\s+}{ }mg; 
        $role =~ s{[^a-z0-9- ]}{}mg;
        $role =~ s{ }{-}mg;
        push(@{$user->{roles}},$role) unless (grep {$_ eq $role} @{$user->{roles}});
    }

    $user->{email} = $email if $email =~ /\S+/;

    $self->store->save($user);

    $self->print_template('roles', { roles => { $self->all_roles } });
}

sub find_roles {
    my $self = shift;
    my $name = shift;

    foreach my $role ($self->all_users) {
        return $role if ($role->{name} eq $name);
    }

    { name => $name , roles => [] };
}

sub all_roles {
    my $self = shift;

    my %lib = ();

    foreach my $user ($self->all_users) {
        my $roles = $user->{roles};
        foreach my $role (@$roles) {
            push(@{$lib{$role}},$user);
        }
    }

    %lib;
}

sub all_users {
    my $self = shift;

    my @users = ();

    $self->store->each(sub {
       push(@users, shift); 
        });

    @users;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;
