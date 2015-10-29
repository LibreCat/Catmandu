package Catmandu::Importer;

use Catmandu::Sane;

our $VERSION = '0.9502';

use Catmandu::Util qw(io data_at is_value is_string is_array_ref is_hash_ref);
use LWP::UserAgent;
use HTTP::Request ();
use URI ();
use URI::Template ();
use Moo::Role;
use namespace::clean;

with 'Catmandu::Logger';
with 'Catmandu::Iterable';
with 'Catmandu::Fixable';
with 'Catmandu::Serializer';

around generator => sub {
    my ($orig, $self) = @_;
    my $generator = $orig->($self);

    if (my $fixer = $self->_fixer) {
        $generator = $fixer->fix($generator);
    }

    if (defined(my $path = $self->data_path)) {
        return sub {
            state @buf;
            while (1) {
                return shift @buf if @buf;
                # TODO use something faster than data_at
                @buf = data_at($path, $generator->() // return);
                next;        
            }
        };    
    }

    $generator;
};

has file => (is => 'lazy', init_arg => undef);
has _file_template => (is => 'ro', predicate => 'has_file', init_arg => 'file');
has variables => (is => 'ro', predicate => 1);
has fh => (is => 'ro', lazy => 1, builder => 1);
has encoding => (is => 'ro', builder=> 1);
has data_path => (is => 'ro');
has http_method => (is => 'lazy');
has http_headers => (is => 'lazy');
has http_agent => (is => 'ro', predicate => 1);
has http_max_redirect => (is => 'ro', predicate => 1);
has http_timeout => (is => 'ro', predicate => 1);
has http_verify_hostname => (is => 'ro', default => sub { 1 });
has http_body => (is => 'ro', predicate => 1);
has _http_client  => (is => 'ro', lazy => 1, builder => '_build_http_client', init_arg => undef);

sub _build_encoding {
    ':utf8';
}

sub _build_file {
    my ($self) = @_;
    return \*STDIN unless $self->has_file;
    my $file = $self->_file_template;
    if (is_string($file) && $self->has_variables) {
        my $template = URI::Template->new($file);
        my $vars = $self->variables;
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
    $file;
}

sub _build_fh {
    my ($self) = @_;
    my $file = $self->file;
    my $body;
    if (is_string($file) && $file =~ m!^https?://!) {
        my $req = HTTP::Request->new($self->http_method, $file, $self->http_headers);

        if ($self->has_http_body) {
            $body = $self->http_body;
            if (ref $body) {
                $body = $self->serialize($body);
            } elsif ($self->has_variables) {
                my $vars = $self->variables;
                if (is_hash_ref($vars)) { # named variables
                    for my $key (keys %$vars) {
                        my $var = $vars->{$key};
                        $body =~ s/{$key}/$var/; 
                    }
                } else { # positional variables
                    if (is_value($vars)) {
                        $vars = [split ',', $vars];
                    }
                    for my $var (@$vars) {
                        $body =~ s/{\w+}/$var/; 
                    }
                }
            }

            $req->content($body);
        }

        my $res = $self->_http_client->request($req);
        unless ($res->is_success) {
            my $res_headers = [];
            for my $header ($res->header_field_names) {
                push @$res_headers, $header, $res->header($header);
            }
            Catmandu::HTTPError->throw({
                code             => $res->code,
                message          => $res->status_line,
                url              => $file,
                method           => $self->http_method,
                request_headers  => $self->http_headers,
                request_body     => $body,
                response_headers => $res_headers,
                response_body    => $res->decoded_content,
            });
        }

        my $content = $res->decoded_content;
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

sub _build_http_client {
    my ($self) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->agent($self->http_agent) if $self->has_http_agent;
    $ua->max_redirect($self->http_max_redirect) if $self->has_http_max_redirect;
    $ua->timeout($self->http_timeout) if $self->has_http_timeout;
    $ua->ssl_opts(verify_hostname => $self->http_verify_hostname);
    $ua->protocols_allowed([qw(http https)]);
    $ua->env_proxy;
    $ua;
}

sub readline {
    $_[0]->fh->getline;
}

sub readall {
    join '', $_[0]->fh->getlines;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Importer - Namespace for packages that can import

=head1 SYNOPSIS

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
            my $name = $self->readline;
            return defined $name ? { "hello" => $name } : undef;
        };
    } 

    package main;

    use Catmandu;

    my $importer = Catmandu->importer('Hello', file => '/tmp/names.txt');
    $importer->each(sub {
        my $items = shift;
        .
        .
        .
    });

    # Or on the command line
    $ catmandu convert Hello to YAML < /tmp/names.txt
    # Fetch remote content
    $ catmandu convert JSON --file http://example.com/data.json to YAML

=head1 DESCRIPTION

A Catmandu::Importer is a Perl package that can import data from an external
source (a file, the network, ...). Most importers read from an input stream, 
such as STDIN, a given file, or an URL to fetch data from, so this base class
provides helper method for consuming the input stream once.

Every Catmandu::Importer is a L<Catmandu::Fixable> and thus inherits a 'fix'
parameter that can be set in the constructor. When given then each item returned
by the generator will be automatically Fixed using one or more L<Catmandu::Fix>es.
E.g.
    
    my $importer = Catmandu->importer('Hello',fix => ['upcase(hello)']);
    $importer->each( sub {
        my $item = shift ; # Every item will be upcased... 
    } );

Every Catmandu::Importer is a L<Catmandu::Iterable> and inherits the methods (C<first>,
C<each>, C<to_array>...) etc.

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

An ARRAY of one or more fixes or file scripts to be applied to imported items.

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
    my $importer = Catmandu->importer('Hello',
        file => 'http://example.com/{id}',
        variables => {id => 1234},
    );
    # positional arguments
    {variables => "1234,768"}
    # or
    {variables => [1234,768]}

=back

=head1 HTTP CONFIGURATION

These options are only relevant if C<file> is a url. See L<LWP::UserAgent> for details about these options.

=over

=item http_method

=item http_headers

=item http_agent

=item http_max_redirect

=item http_timeout 

=item http_verify_hostname

=back

=head1 METHODS

=head2 readline

Read a line from the input stream. Equivalent to C<< $importer->fh->getline >>.

=head2 readall

Read the whole input stream as string.

=head2 first, each, rest , ...

See L<Catmandu::Iterable> for all inherited methods.

=head1 SEE ALSO

L<Catmandu::Iterable> , L<Catmandu::Fix> ,
L<Catmandu::Importer::CSV>, L<Catmandu::Importer::JSON> , L<Catmandu::Importer::YAML>

=cut
