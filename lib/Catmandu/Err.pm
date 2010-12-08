use MooseX::Declare;

class Catmandu::Err {
    use overload q("") => \&stringify;

    has message => (is => 'rw', isa => 'Str', required => 1);

    around BUILDARGS ($class: $msg) {
        { message => $msg };
    }

    method throw ($class: @args) {
        die $class->new(@args);
    }

    method rethrow () {
        die $self;
    }

    method stringify () {
        $self->message;
    }
}

class Catmandu::HTTPErr extends Catmandu::Err {
    use HTTP::Status;

    has code => (is => 'rw', isa => 'Int', required => 1);

    around BUILDARGS ($class: $code, $msg?) {
        { code => $code, message => $msg || HTTP::Status::status_message($code) };
    }
}

1;

