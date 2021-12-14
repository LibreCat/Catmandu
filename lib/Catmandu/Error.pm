package Catmandu::Error;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Moo;
use namespace::clean;

extends 'Throwable::Error';

with 'Catmandu::Logger';

has message => (
    is     => 'lazy',
    coerce => sub {
        my $msg = $_[0] // "";
        $msg =~ s/\s+$//;
        $msg;
    }
);

sub BUILD {
    my ($self) = @_;
    my $msg = $self->log_message;
    if ($self->log->is_debug) {
        $msg .= "\n\n" . $self->stack_trace->as_string;
    }
    $self->log->error($msg);
}

sub log_message {
    $_[0]->message;
}

sub _build_message {
    "";
}

package Catmandu::Error::Source;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Moo::Role;
use Catmandu::Util qw(is_string);
use namespace::clean;

has source => (is => 'rw', writer => 'set_source');

sub _source_log_message {
    my $msg = "";
    if (is_string(my $source = $_[0]->source)) {
        $msg .= "\nSource:";
        for (split(/\n/, $source)) {
            $msg .= "\n\t$_";
        }
    }
    $msg;
}

package Catmandu::BadVal;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Moo;
use namespace::clean;

extends 'Catmandu::Error';

package Catmandu::BadArg;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Moo;
use namespace::clean;

extends 'Catmandu::BadVal';

package Catmandu::NotImplemented;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Moo;
use namespace::clean;

extends 'Catmandu::Error';

package Catmandu::NoSuchPackage;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Moo;
use namespace::clean;

extends 'Catmandu::Error';

has package_name => (is => 'ro');

sub log_message {
    my ($self)   = @_;
    my $err      = $self->message;
    my $pkg_name = $self->package_name;
    my $msg      = "Failed to load $pkg_name";
    if (my ($type, $name)
        = $pkg_name =~ /^Catmandu::(Importer|Exporter|Store)::(\S+)/)
    {
        $msg
            = "Can't find the "
            . lc($type)
            . " '$name' in your configuration file or $pkg_name is not installed.";
    }
    elsif ($pkg_name =~ /^Catmandu::Fix::\S+/) {
        my ($fix_name) = $pkg_name =~ /([^:]+)$/;
        if ($fix_name =~ /^[a-z]/) {
            $msg
                = "Tried to execute the fix '$fix_name' but can't find $pkg_name on your system.";
        }
    }
    $msg .= "\nError: $err";
    $msg .= "\nPackage name: $pkg_name";
    $msg;
}

package Catmandu::FixParseError;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Moo;
use namespace::clean;

extends 'Catmandu::Error';

with 'Catmandu::Error::Source';

sub log_message {
    my ($self) = @_;
    my $err    = $self->message;
    my $msg    = "Syntax error in your fixes...";
    $msg .= "\nError: $err";
    $msg .= $self->_source_log_message;
    $msg;
}

package Catmandu::NoSuchFixPackage;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Moo;
use namespace::clean;

extends 'Catmandu::NoSuchPackage';

with 'Catmandu::Error::Source';

has fix_name => (is => 'ro');

around log_message => sub {
    my ($orig, $self) = @_;
    my $fix_name = $self->fix_name;
    my $msg      = $orig->($self);
    $msg .= "\nFix name: $fix_name" if $fix_name;
    $msg .= $self->_source_log_message;
    $msg;
};

package Catmandu::BadFixArg;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Moo;
use namespace::clean;

extends 'Catmandu::BadArg';

with 'Catmandu::Error::Source';

has package_name => (is => 'ro');
has fix_name     => (is => 'ro');

sub log_message {
    my ($self)   = @_;
    my $err      = $self->message;
    my $fix_name = $self->fix_name;
    my $msg
        = "The fix '$fix_name' was called with missing or wrong arguments.";
    $msg .= "\nError: $err";
    $msg .= $self->_source_log_message;
    $msg;
}

package Catmandu::FixError;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Moo;
use Data::Dumper;
use namespace::clean;

extends 'Catmandu::Error';

has data => (is => 'ro');
has fix  => (is => 'ro');

sub log_message {
    my ($self) = @_;
    my $err    = $self->message;
    my $fix    = $self->fix;
    my $data   = $self->data;
    my $msg    = "One of your fixes threw an error...";
    $msg .= "\nError: $err";
    $msg .= "\nSource: $fix"             if $fix;
    $msg .= "\nInput:\n" . Dumper($data) if defined $data;
    $msg;
}

package Catmandu::HTTPError;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Moo;
use Data::Dumper;
use namespace::clean;

# avoid circular dependencies
require Catmandu::Util;

extends 'Catmandu::Error';

has code             => (is => 'ro');
has url              => (is => 'ro');
has method           => (is => 'ro');
has request_headers  => (is => 'ro');
has request_body     => (is => 'ro');
has response_headers => (is => 'ro');
has response_body    => (is => 'ro');

sub log_message {
    my ($self)           = @_;
    my $err              = $self->message;
    my $code             = $self->code;
    my $url              = $self->url;
    my $method           = $self->method;
    my $request_body     = $self->request_body;
    my $response_body    = $self->response_body;
    my $request_headers  = $self->request_headers;
    my $response_headers = $self->response_headers;
    my $msg              = "Got a HTTP error...";
    $msg .= "\nError: $err";
    $msg .= "\nCode: $code";
    $msg .= "\nURL: $url";
    $msg .= "\nMethod: $method";
    $msg .= "\nRequest headers: "
        . $self->_headers_to_string($request_headers);

    if (Catmandu::Util::is_string($request_body)) {
        $msg .= "\nRequest body: \n" . $self->_indent($request_body);
    }
    $msg .= "\nResponse headers: "
        . $self->_headers_to_string($response_headers);
    if (Catmandu::Util::is_string($response_body)) {
        $msg .= "\nResponse body: \n" . $self->_indent($response_body);
    }
    $msg;
}

sub _headers_to_string {
    my ($self, $headers) = @_;
    my $str = "";
    for (my $i = 0; $i < @$headers; $i++) {
        $str .= "\n\t" . $headers->[$i++] . ": " . $headers->[$i];
    }
    $str;
}

sub _indent {
    my ($self, $str) = @_;
    $str =~ s/([^\r\n]+)/\t$1/g;
    $str;
}

1;

__END__

=pod

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
