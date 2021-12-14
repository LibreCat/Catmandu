package Catmandu::Importer;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Catmandu::Util qw(io is_value is_string is_array_ref is_hash_ref);
use Catmandu::Util::Path qw(as_path);
use LWP::UserAgent;
use HTTP::Request ();
use URI           ();
use URI::Template ();
use Moo::Role;
use namespace::clean;

with 'Catmandu::Logger';
with 'Catmandu::Iterable';
with 'Catmandu::IterableOnce';
with 'Catmandu::Fixable';
with 'Catmandu::Serializer';

around generator => sub {
    my ($orig, $self) = @_;

    my $generator = $orig->($self);

    if (my $fixer = $self->_fixer) {
        $generator = $fixer->fix($generator);
    }

    if (defined(my $path = $self->data_path)) {
        my $getter = as_path($path)->getter;
        return sub {
            state @buf;
            while (1) {
                return shift @buf if @buf;
                @buf = @{$getter->($generator->() // return)};
                next;
            }
        };
    }

    $generator;
};

has file => (is => 'lazy', init_arg => undef);
has _file_template =>
    (is => 'ro', predicate => 'has_file', init_arg => 'file');
has variables         => (is => 'ro', predicate => 1);
has fh                => (is => 'ro', lazy      => 1, builder => 1);
has encoding          => (is => 'ro', builder   => 1);
has data_path         => (is => 'ro');
has user_agent        => (is => 'ro');
has http_method       => (is => 'lazy');
has http_headers      => (is => 'lazy');
has http_agent        => (is => 'ro', predicate => 1);
has http_max_redirect => (is => 'ro', predicate => 1);
has http_timeout      => (is => 'ro', default   => sub {180});   # LWP default
has http_verify_hostname => (is => 'ro', default   => sub {1});
has http_retry           => (is => 'ro', predicate => 1);
has http_timing          => (is => 'ro', predicate => 1);
has http_body            => (is => 'ro', predicate => 1);
has _http_client => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_http_client',
    init_arg => 'user_agent'
);
has _http_timing_tries => (is => 'lazy');
has ignore_404         => (is => 'ro');

sub _build_encoding {
    ':utf8';
}

sub _build_file {
    my ($self) = @_;
    return \*STDIN unless $self->has_file;
    my $file = $self->_file_template;
    if (is_string($file) && $self->has_variables) {
        my $template = URI::Template->new($file);
        my $vars     = $self->variables;
        if (is_value($vars)) {
            $vars = [split ',', $vars];
        }
        if (is_array_ref($vars)) {
            my @keys = $template->variables;
            my @vals = @$vars;
            $vars = {};
            $vars->{shift @keys} = shift @vals while @keys && @vals;
        }
        $file = $template->process_to_string(%$vars);
    }
    if (is_string($file) && $file !~ m!^https?://! && !-r $file) {
        Catmandu::BadArg->throw("file '$file' doesn't exist");
    }
    $file;
}

sub _build_fh {
    my ($self) = @_;

    my $file = $self->file;

    # get remote content
    if (is_string($file) && $file =~ m!^https?://!) {
        my $body;
        if ($self->has_http_body) {
            $body = $self->http_body;

            if (ref $body) {
                $body = $self->serialize($body);
            }

            if ($self->has_variables) {
                my $vars = $self->variables;
                if (is_hash_ref($vars)) {    # named variables
                    for my $key (keys %$vars) {
                        my $var = $vars->{$key};
                        $body =~ s/{$key}/$var/;
                    }
                }
                else {                       # positional variables
                    if (is_value($vars)) {
                        $vars = [split ',', $vars];
                    }
                    for my $var (@$vars) {
                        $body =~ s/{\w+}/$var/;
                    }
                }
            }
        }

        my $content = $self->_http_request(
            $self->http_method, $file, $self->http_headers,
            $body, $self->_http_timing_tries,
        );

        return io(\$content, mode => 'r', binmode => $_[0]->encoding);
    }

    io($file, mode => 'r', binmode => $_[0]->encoding);
}

sub _build_http_headers {
    [];
}

sub _build_http_method {
    'GET';
}

sub _build__http_timing_tries {
    my ($self) = @_;

    if ($self->has_http_timing) {
        my @timing_tries = $self->http_timing =~ /(\d+(?:\.\d+)*)/g;
        return \@timing_tries;
    }
    elsif ($self->has_http_retry) {
        my @timing_tries = (1) x $self->http_retry;
        return \@timing_tries;
    }
    return;
}

sub _build_http_client {
    my ($self) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->timeout($self->http_timeout);
    $ua->agent($self->http_agent) if $self->has_http_agent;
    $ua->max_redirect($self->http_max_redirect)
        if $self->has_http_max_redirect;
    $ua->ssl_opts(verify_hostname => $self->http_verify_hostname);
    $ua->protocols_allowed([qw(http https)]);
    $ua->env_proxy;
    $ua;
}

sub _http_request {
    my ($self, $method, $url, $headers, $body, $timing_tries) = @_;

    my $client = $self->_http_client;

    my $req = HTTP::Request->new($method, $url, $headers || []);
    $req->content($body) if defined $body;

    my $res = $client->request($req);

    if ($res->code =~ /^408|500|502|503|504$/ && $timing_tries) {
        my @tries = @$timing_tries;
        while (my $sleep = shift @tries) {
            sleep $sleep;
            $res = $client->request($req->clone);
            last if $res->code !~ /^408|500|502|503|504$/;
        }
    }

    my $res_body = $res->decoded_content;

    unless ($res->is_success) {
        my $res_headers = [];
        for my $header ($res->header_field_names) {
            my $val = $res->header($header);
            push @$res_headers, $header, $val;
        }
        Catmandu::HTTPError->throw(
            {
                code             => $res->code,
                message          => $res->status_line,
                url              => $url,
                method           => $method,
                request_headers  => $headers,
                request_body     => $body,
                response_headers => $res_headers,
                response_body    => $res_body,
            }
        );
    }

    $res_body;
}

sub readline {
    warnings::warnif("deprecated",
        "readline is deprecated, fh->getline instead");
    $_[0]->fh->getline;
}

sub readall {
    warnings::warnif("deprecated",
        "readall is deprecated, join('',fh->getlines) instead");
    join '', $_[0]->fh->getlines;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Importer - Namespace for packages that can import

=head1 SYNOPSIS

    # From the command line

    # JSON is an importer and YAML an exporter
    $ catmandu convert JSON to YAML < data.json

    # OAI is an importer and JSON an exporter
    $ catmandu convert OAI --url http://biblio.ugent.be/oai to JSON 

    # Fetch remote content
    $ catmandu convert JSON --file http://example.com/data.json to YAML
    
    # From Perl
    
    use Catmandu;
    use Data::Dumper;

    my $importer = Catmandu->importer('JSON', file => 'data.json');

    $importer->each(sub {
        my $item = shift;
        print Dumper($item);
    });

    my $num = $importer->count;

    my $first_item = $importer->first;

    # Convert OAI to JSON in Perl
    my $importer = Catmandu->importer('OAI', url => 'http://biblio.ugent.be/oai');
    my $exporter = Catmandu->exporter('JSON');

    $exporter->add_many($importer);

=head1 DESCRIPTION

A Catmandu::Importer is a Perl package that can generate structured data from
sources such as JSON, YAML, XML, RDF or network protocols such as Atom, OAI-PMH,
SRU and even DBI databases. Given an Catmandu::Importer a programmer can read
data from using one of the many L<Catmandu::Iterable> methods:


    $importer->to_array;
    $importer->count;
    $importer->each(\&callback);
    $importer->first;
    $importer->rest;
    ...etc...

Every Catmandu::Importer is also L<Catmandu::Fixable> and thus inherits a 'fix'
parameter that can be set in the constructor. When given a 'fix' parameter, then each 
item returned by the generator will be automatically Fixed using one or 
more L<Catmandu::Fix>es.
E.g.
    
    my $importer = Catmandu->importer('JSON',fix => ['upcase(title)']);
    $importer->each( sub {
        my $item = shift ; # Every $item->{title} is now upcased... 

    });

    # or via a Fix file
    my $importer = Catmandu->importer('JSON',fix => ['/my/fixes.txt']);
    $importer->each( sub {
        my $item = shift ; # Every $item->{title} is now upcased... 

    });

=head1 CONFIGURATION

=over

=item file

Read input from a local file given by its path. If the path looks like a
url, the content will be fetched first and then passed to the importer.
Alternatively a scalar reference can be passed to read from a string.

=item fh

Read input from an L<IO::Handle>. If not specified, L<Catmandu::Util::io> is used to
create the input stream from the C<file> argument or by using STDIN.

=item encoding

Binmode of the input stream C<fh>. Set to C<:utf8> by default.

=item fix

An ARRAY of one or more Fix-es or Fix scripts to be applied to imported items.

=item data_path

The data at C<data_path> is imported instead of the original data.

   # given this imported item:
   {abc => [{a=>1},{b=>2},{c=>3}]}
   # with data_path 'abc', this item gets imported instead:
   [{a=>1},{b=>2},{c=>3}]
   # with data_path 'abc.*', 3 items get imported:
   {a=>1}
   {b=>2}
   {c=>3}

=item variables

Variables given here will interpolate the C<file> and C<http_body> options. The
syntax is the same as L<URI::Template>.

    # named arguments
    my $importer = Catmandu->importer('JSON',
        file => 'http://{server}/{path}',
        variables => {server => 'biblio.ugent.be', path => 'file.json'},
    );

    # positional arguments
    my $importer = Catmandu->importer('JSON',
        file => 'http://{server}/{path}',
        variables => 'biblio.ugent.be,file.json',
    );

    # or
    my $importer = Catmandu->importer('JSON',
        url => 'http://{server}/{path}',
        variables => ['biblio.ugent.be','file.json'],
    );

    # or via the command line
    $ catmandu convert JSON --file 'http://{server}/{path}' --variables 'biblio.ugent.be,file.json'

=back

=head1 HTTP CONFIGURATION

These options are only relevant if C<file> is a url. See L<LWP::UserAgent> for details about these options.

=over

=item http_body

Set the GET/POST message body.

=item http_method

Set the type of HTTP request 'GET', 'POST' , ...

=item http_headers

A reference to a HTTP::Headers objects.

=back

=head2 Set an own HTTP client

=over 

=item user_agent(LWP::UserAgent->new(...))

Set an own HTTP client

=back

=head2 Alternative set the parameters of the default client

=over

=item http_agent

A string containing the name of the HTTP client.

=item http_max_redirect

Maximum number of HTTP redirects allowed.

=item http_timeout 

Maximum execution time.

=item http_verify_hostname

Verify the SSL certificate.

=item http_retry

Maximum times to retry the HTTP request if it temporarily fails. Default is not
to retry.  See L<LWP::UserAgent::Determined> for the HTTP status codes
that initiate a retry.

=item http_timing

Maximum times and timeouts to retry the HTTP request if it temporarily fails. Default is not
to retry.  See L<LWP::UserAgent::Determined> for the HTTP status codes
that initiate a retry and the format of the timing value.

=back

=head1 METHODS

=head2 first, each, rest , ...

See L<Catmandu::Iterable> for all inherited methods.

=head1 CODING

Create your own importer by creating a Perl package in the Catmandu::Importer namespace that
implements C<Catmandu::Importer>. Basically, you need to create a method 'generate' which 
returns a callback that creates one Perl hash for each call:

    my $importer = Catmandu::Importer::Hello->new;

    $importer->generate(); # record
    $importer->generate(); # next record
    $importer->generate(); # undef = end of stream

Here is an example of a simple C<Hello> importer:

    package Catmandu::Importer::Hello;

    use Catmandu::Sane;
    use Moo;

    with 'Catmandu::Importer';

    sub generator {
        my ($self) = @_;
        state $fh = $self->fh;
        my $n = 0;
        return sub {
            $self->log->debug("generating record " . ++$n);
            my $name = $self->fh->readline;
            return defined $name ? { "hello" => $name } : undef;
        };
    }

    1;

This importer can be called via the command line as:

    $ catmandu convert Hello to JSON < /tmp/names.txt
    $ catmandu convert Hello to YAML < /tmp/names.txt
    $ catmandu import Hello to MongoDB --database_name test < /tmp/names.txt

Or, via Perl

    use Catmandu;

    my $importer = Catmandu->importer('Hello', file => '/tmp/names.txt');
    $importer->each(sub {
        my $items = shift;
    });

=head1 SEE ALSO

L<Catmandu::Iterable> , L<Catmandu::Fix> ,
L<Catmandu::Importer::CSV>, L<Catmandu::Importer::JSON> , L<Catmandu::Importer::YAML>

=cut
