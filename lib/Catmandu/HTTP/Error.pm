package Catmandu::HTTP::Error;
use Catmandu::Class qw(error_code body headers);
use Catmandu::Util;

sub error_codes {
    state $error_codes = { # stolen from HTTP::Status
        300 => 'Multiple Choices',
        301 => 'Moved Permanently',
        302 => 'Found',
        303 => 'See Other',
        304 => 'Not Modified',
        305 => 'Use Proxy',
        307 => 'Temporary Redirect',
        400 => 'Bad Request',
        401 => 'Unauthorized',
        402 => 'Payment Required',
        403 => 'Forbidden',
        404 => 'Not Found',
        405 => 'Method Not Allowed',
        406 => 'Not Acceptable',
        407 => 'Proxy Authentication Required',
        408 => 'Request Timeout',
        409 => 'Conflict',
        410 => 'Gone',
        411 => 'Length Required',
        412 => 'Precondition Failed',
        413 => 'Request Entity Too Large',
        414 => 'Request-URI Too Large',
        415 => 'Unsupported Media Type',
        416 => 'Request Range Not Satisfiable',
        417 => 'Expectation Failed',
        422 => 'Unprocessable Entity',            # RFC 2518 (WebDAV)
        423 => 'Locked',                          # RFC 2518 (WebDAV)
        424 => 'Failed Dependency',               # RFC 2518 (WebDAV)
        425 => 'No code',                         # WebDAV Advanced Collections
        426 => 'Upgrade Required',                # RFC 2817
        449 => 'Retry with',                      # unofficial Microsoft
        500 => 'Internal Server Error',
        501 => 'Not Implemented',
        502 => 'Bad Gateway',
        503 => 'Service Unavailable',
        504 => 'Gateway Timeout',
        505 => 'HTTP Version Not Supported',
        506 => 'Variant Also Negotiates',         # RFC 2295
        507 => 'Insufficient Storage',            # RFC 2518 (WebDAV)
        509 => 'Bandwidth Limit Exceeded',        # unofficial
        510 => 'Not Extended',                    # RFC 2774
    };
}

sub build_args {
    my ($self, $code, $body, %headers) = @_;
    $headers{'Content-Type'} ||= 'text/plain';
    { error_code => $code,
      body => [ $body // $self->error_codes->{$code} ],
      headers => [ %headers ] };
}

sub throw {
    my ($self, @args) = @_;
    $self = $self->new(@args) unless ref $self;
    confess $self if $self->is_server_error;
    die $self;
}

sub message {
    $_[0]->error_codes->{$_[0]->error_code};
}

sub psgi_response {
    my $self = $_[0]; [ $self->error_code, $self->headers, $self->body ];
}

sub psgi_app {
    my $self = $_[0]; sub { $self->psgi_response };
}

sub is_redirect {
    $_[0]->error_code >= 300 && $_[0]->error_code < 400;
}

sub is_client_error {
    $_[0]->error_code >= 400 && $_[0]->error_code < 500;
}

sub is_server_error {
    $_[0]->error_code >= 500 && $_[0]->error_code < 600;
}

1;

