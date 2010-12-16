package Catmandu::Err;

use namespace::autoclean;
use Moose;
use overload q("") => sub {
    $_[0]->stringify;
};

sub throw {
    my $class = shift; die $class->new(@_);
}

sub rethrow {
    die $_[0];
}

__PACKAGE__->meta->make_immutable;

package Catmandu::HTTPErr;

use namespace::autoclean;
use Moose;
use HTTP::Status;
use Data::Dumper::Concise;

extends qw(Catmandu::Err);

has code    => (is => 'rw', isa => 'Int', required => 1);
has body    => (is => 'rw', required => 1, lazy => 1, builder => '_build_body');
has headers => (is => 'rw', required => 1, lazy => 1, builder => '_build_headers');

around BUILDARGS => sub {
    my ($orig, $class, $code, @args) = @_;
    my $args = $class->$orig(@args);
    $args->{code} = $code;
    $args;
};

sub _build_body {
    HTTP::Status::status_message($_[0]->code);
}

sub _build_headers {
    {};
}

sub stringify {
    my $self = $_[0];
    my $body = $self->body;
    ref $body ?
        Dumper($body) :
        $body;
}

__PACKAGE__->meta->make_immutable;

1;

