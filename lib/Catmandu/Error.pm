package Catmandu::Error;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Throwable::Error';

with 'Catmandu::Logger';

sub BUILD {
    my ($self) = @_;
    my $msg = $self->log_message;
    if ($self->log->is_debug) {
        $msg .= "\n\n" . $self->stack_trace->as_string;
    }
    $self->log->error($msg);
}

sub log_message {
    my ($self) = @_;
    $self->message;
}

package Catmandu::BadVal;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::Error';

package Catmandu::BadArg;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::BadVal';

package Catmandu::NotImplemented;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::Error';

package Catmandu::NoSuchPackage;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::Error';

has package_name => (is => 'ro');

sub log_message {
    my ($self) = @_;
    my $msg = $self->message;
    $msg .= "\nPackage name: " . $self->package_name;
    $msg;
}

package Catmandu::FixParseError;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::Error';

has source => (is => 'ro');

package Catmandu::NoSuchFixPackage;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::NoSuchPackage';

has fix_name => (is => 'ro');
has source => (is => 'rw', writer => 'set_source');

sub log_message {
    my ($self) = @_;
    my $msg = $self->message;
    $msg .= "\nFix name: " . $self->fix_name;
    $msg .= "\nPackage name: " . $self->package_name;
    $msg;
}

package Catmandu::BadFixArg;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::BadArg';

has package_name => (is => 'ro');
has fix_name => (is => 'ro');
has source => (is => 'rw', writer => 'set_source');

package Catmandu::FixError;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::Error';

has data => (is => 'ro');
has fix => (is => 'ro');

package Catmandu::HTTPError;
use Catmandu::Sane;
use Catmandu::Util qw(is_string);
use Moo;
use namespace::clean;

extends 'Catmandu::Error';

has code => (is => 'ro');
has url => (is => 'ro');
has method => (is => 'ro');
has request_headers => (is => 'ro');
has request_body => (is => 'ro');
has response_headers => (is => 'ro');
has response_body => (is => 'ro');

sub log_message {
    my ($self) = @_;
    my $msg = $self->message;
    $msg .= "\nURL: " . $self->url;
    $msg .= "\nMethod: " . $self->method;
    $msg .= "\nRequest headers: " . $self->_headers_to_string($self->request_headers);
    if (is_string($self->request_body)) {
        $msg .= "\nRequest body: \n" . $self->_indent($self->request_body);
    }
    $msg .= "\nResponse code: " . $self->code;
    $msg .= "\nResponse headers: " . $self->_headers_to_string($self->response_headers);
    if (is_string($self->response_body)) {
        $msg .= "\nResponse body: \n" . $self->_indent($self->response_body);
    }
    $msg;
}

sub _headers_to_string {
    my ($self, $headers) = @_;
    my $str = "";
    for (my $i=0; $i < @$headers; $i++) {
        $str .= "\n\t" . $headers->[$i++] . ": " . $headers->[$i];
    }
    $str;
}

sub _indent {
    my ($self, $str) = @_;
    $str =~ s/([^\r\n]+)/\t$1/g;
    $str;
}

=head1 NAME

Catmandu::Error - Catmandu error hierarchy

=head1 SYNOPSIS

    use Catmandu::Sane;

    sub be_naughty {
        Catmandu::BadArg->throw("very naughty") if shift;
    }

    try {
        be_naughty(1);
    } catch_case [
        'Catmandu::BadArg' => sub {
            say "sorry";
        }
    ];

=head1 CURRRENT ERROR HIERARCHY
    Throwable::Error
        Catmandu::Error
            Catmandu::BadVal
                Catmandu::BadArg
                    Catmandu::BadFixArg
            Catmandu::NotImplemented
            Catmandu::NoSuchPackage
                Catmandu::NoSuchFixPackage
            Catmandu::FixParseError
            Catmandu::FixError
            Catmandu::HTTPError

=head1 SEE ALSO

L<Throwable>

=cut

1;
