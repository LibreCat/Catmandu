package Catmandu::Err;

use Moose;
use overload q("") => sub { $_[0]->message }, fallback => 1;

has message => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

sub throw {
    my $class = shift; die $class->new(@_);
}

around BUILDARGS => sub {
    my $sub   = shift;
    my $class = shift;

    if (@_ == 1 && ! ref $_[0]) {
        $class->$sub(message => $_[0]);
    } else {
        $class->$sub(@_);
    }
};

__PACKAGE__->meta->make_immutable;

package Catmandu::Err::HTTP;

use Moose;
use HTTP::Status;

extends 'Catmandu::Err';

has code => (
    is => 'rw',
    isa => 'Int',
    required => 1,
);

around BUILDARGS => sub {
    my ($sub, $class, $code, $msg) = @_;
    $msg ||= HTTP::Status::status_message($code);
    $class->$sub(code => $code, message => $msg);
};

__PACKAGE__->meta->make_immutable;

package Catmandu::Err;

__PACKAGE__;

