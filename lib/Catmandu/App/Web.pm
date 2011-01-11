package Catmandu::App::Web;
# VERSION
use namespace::autoclean;
use Moose;
use Hash::MultiValue;

has env        => (is => 'ro', required => 1);
has req        => (is => 'ro');
has res        => (is => 'ro', builder => '_build_res');
has parameters => (is => 'ro', builder => '_build_parameters');

sub BUILD {
    my $self = $_[0];
    $self->req($self->new_request);
}

sub _build_res {
    my ($self) = @_;
    $_[0]->req->new_response(200);
}

sub _build_parameters {
    Hash::MultiValue->new;
}

sub new_request {
    my ($self, $env) = @_;
    Catmandu::App::Req->new($env);
}

sub request  { $_[0]->{req} }
sub response { $_[0]->{res} }

sub param {
    my ($self, $key) = @_;

    if ($key) {
        return $self->parameters->get_all($key) if wantarray;
        return $self->parameters->get($key);
    }

    keys %{$self->parameters};
}

__PACKAGE__->meta->make_immutable;

1;

