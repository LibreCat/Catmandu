package Catmandu::App::Web;
# VERSION
use Moose;
use Moose::Util::TypeConstraints;
use Catmandu::App::Env;
use Hash::MultiValue;

with qw(Catmandu::App::Env);

subtype 'MultiHash'
    => as 'Object'
    => where { $_->isa('Hash::MultiValue') };

coerce 'MultiHash'
    => from 'ArrayRef'
    => via { Hash::MultiValue->new(@$_) };

coerce 'MultiHash'
    => from 'HashRef'
    => via { Hash::MultiValue->from_mixed($_) };

has res => (
    is => 'ro',
    isa => 'Plack::Response',
    lazy => 1,
    builder => '_build_res',
);

has parameters => (
    is => 'ro',
    isa => 'MultiHash',
    coerce => 1,
    lazy => 1,
    builder => '_build_parameters',
);

sub _build_res {
    $_[0]->req->new_response(200);
}

sub _build_parameters {
    Hash::MultiValue->new;
}

sub response {
    $_[0]->res;
}

sub param {
    my ($self, $key) = @_;

    if ($key) {
        return $self->parameters->get_all($key) if wantarray;
        return $self->parameters->get($key);
    }

    keys %{$self->parameters};
}

__PACKAGE__->meta->make_immutable;

no Moose::Util::TypeConstraints;
no Moose;

1;

