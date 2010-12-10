package Catmandu::Err;

use namespace::autoclean;
use Moose;
use overload q("") => \&stringify;

has message => (is => 'rw', isa => 'Str', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $msg) = @_;
    { message => $msg };
};

sub throw {
    my $class = shift; die $class->new(@_);
}

sub rethrow {
    die $_[0];
}

sub stringify {
    $_[0]->message;
}

__PACKAGE__->meta->make_immutable;

package Catmandu::HTTPErr;

use namespace::autoclean;
use Moose;
use HTTP::Status;

extends qw(Catmandu::Err);

has code => (is => 'rw', isa => 'Int', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $code, $msg) = @_;
    { code => $code, message => $msg || HTTP::Status::status_message($code) };
};

__PACKAGE__->meta->make_immutable;

1;

