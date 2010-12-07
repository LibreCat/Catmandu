use MooseX::Declare;

class Catmandu::Err {
    use overload q("") => \&stringify;

    has message => (is => 'rw', isa => 'Str', required => 1);

    around BUILDARGS => sub {
        my ($sub, $self, $code, $msg) = @_;
        { message => $msg };
    };

    sub throw {
        my ($self, @args) = @_;
        die $self->new(@args);
    }

    sub rethrow {
        my ($self) = @_;
        die $self;
    }

    sub stringify {
        my ($self) = @_;
        $self->message;
    }
}

class Catmandu::HTTPErr extends Catmandu::Err {
    use HTTP::Status;

    has code => (is => 'rw', isa => 'Int', required => 1);

    around BUILDARGS => sub {
        my ($sub, $self, $code, $msg) = @_;
        { code => $code, message => $msg || HTTP::Status::status_message($code) };
    };
}

1;

