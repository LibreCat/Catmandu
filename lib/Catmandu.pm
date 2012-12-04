package Catmandu;

use Catmandu::Sane;
use Catmandu::Util qw(require_package use_lib read_yaml read_json :is :check);
use File::Spec;

=head1 NAME

Catmandu - a data toolkit

=head1 DESCRIPTION

Importing, transforming, storing and indexing data should be easy.

Catmandu provides a suite of Perl modules to ease the import, storage,
retrieval, export and transformation of metadata records. Combine Catmandu
modules with web application frameworks such as PSGI/Plack, document stores
such as MongoDB and full text indexes as Solr to create a rapid development
environment for digital library services such as institutional repositories and
search engines.

In the LibreCat project it is our goal to provide in open source a set of
programming components to build up digital libraries services suited to your
local needs.

Read an in depth introduction into Catmandu programming in
L<Catmandu::Introduction>.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use Catmandu;

    Catmandu->load;
    Catmandu->load('/config/path', '/another/config/path');

    Catmandu->store->bag('projects')->count;

    Catmandu->config;
    Catmandu->config->{foo} = 'bar';

    use Catmandu -all;
    use Catmandu qw(config store);
    use Catmandu -load;
    use Catmandu -all -load => [qw(/config/path' '/another/config/path)];

=head1 CONFIG

Catmandu configuration options can be stored in a file in the root directory of
your programming project. The file can be YAML, JSON or Perl and is called
C<catmandu.yml>, C<catmandu.json> or C<catmandu.pl>. In this file you can set
the default Catmandu stores and exporters to be used. Here is an example of a
C<catmandu.yml> file:

    store:
      default:
        package: ElasticSearch
        options:
          index_name: myrepository

    exporter:
      default:
        package: YAML

=head2 Split config

For large configs it's more convenient to split the config in several files.
You can do so by including the config hash key in the file name.

    catmandu.yaml
    catmandu.store.yaml
    catmandu.foo.bar.json

Config files are processed in alfabetical order. To keep things simple values
are not merged.  So the contents of C<catmandu.store.yml> will overwrite
C<< Catmandu->config->{store} >> if it already exists.

=head1 EXPORTS

=over

=item config

Same as C<< Catmandu->config >>.

=item store

Same as C<< Catmandu->store >>.

=item importer

Same as C<< Catmandu->importer >>.

=item exporter

Same as C<< Catmandu->exporter >>.

=item export

Same as C<< Catmandu->export >>.

=item export_to_string

Same as C<< Catmandu->export_to_string >>.

=item -all/:all

Import everything.

=item -load/:load

    use Catmandu -load;
    use Catmandu -load => [];
    # is the same as
    Catmandu->load;

    use Catmandu -load => ['/config/path'];
    # is the same as
    Catmandu->load('/config/path');

=back

=cut

use Sub::Exporter::Util qw(curry_method);
use Sub::Exporter -setup => {
    exports => [config   => curry_method,
                store    => curry_method,
                importer => curry_method,
                exporter => curry_method,
                export   => curry_method,
                export_to_string => curry_method],
    collectors => {
        '-load' => \'_import_load',
        ':load' => \'_import_load',
    },
};

sub _import_load {
    my ($self, $value, $data) = @_;
    if (is_array_ref $value) {
        $self->load(@$value);
    } else {
        $self->load;
    }
    1;
}

=head1 METHODS

=head2 default_load_path

Return the path where Catmandu will (optionally) start searching for a
catmandu.yml configuration file.

=head2 default_load_path('/default/path')

Set the location of the default configuration file to a new path.

=cut

sub default_load_path {
    my ($class, $path) = @_;
    state $default_path;
    $default_path = $path if defined $path;
    $default_path //= do {
        my $script = File::Spec->rel2abs($0);
        my ($script_vol, $script_path, $script_name) = File::Spec->splitpath($script);
        $script_path;
    }
}

=head2 load

Load all the configuration options in the catmanu.yml configuraton file.

=head2 load('/path', '/another/path')

Load all the configuration options stored at alternative paths.

=cut

sub load {
    my ($self, @load_paths) = @_;

    push @load_paths, $self->default_load_path unless @load_paths;

    @load_paths = map { File::Spec->rel2abs($_) } split /,/, join ',', @load_paths;

    for my $load_path (@load_paths) {
        my @dirs = grep length, File::Spec->splitdir($load_path);

        for (;@dirs;pop @dirs) {
            my $path = File::Spec->catdir(File::Spec->rootdir, @dirs);

            opendir my $dh, $path or last;

            my @files = sort
                        grep { -f -r File::Spec->catfile($path, $_) }
                        grep { /^catmandu\./ }
                        readdir $dh;
            for my $file (@files) {
                if (my ($keys, $ext) = $file =~ /^catmandu(.*)\.(pl|yaml|yml|json)$/) {
                    $keys = substr $keys, 1 if $keys; # remove leading dot

                    $file = File::Spec->catfile($path, $file);

                    my $config = $self->config;
                    my $c;

                    $config = $config->{$_} ||= {} for split /\./, $keys;

                    given ($ext) {
                        when ('pl')    { $c = do $file }
                        when (/ya?ml/) { $c = read_yaml($file) }
                        when ('json')  { $c = read_json($file) }
                    }
                    $config->{$_} = $c->{$_} for keys %$c;
                }
            }

            if (@files) {
                unshift @{$self->roots}, $path;

                my $lib_path = File::Spec->catdir($path, 'lib');
                if (-d -r $lib_path) {
                    use_lib $lib_path;
                }

                last;
            }
        }
    }
}

=head2 roots

Returns an ARRAYREF of paths where configuration was found. Note that this list
is empty before C<load>.

=cut

sub roots {
    state $roots = [];
}

=head2 root

Returns the first path where configuration was found. Note that this is
C<undef> before C<load>.

=cut

sub root {
    $_[0]->roots->[0];
}

=head2 config

Returns the current configuration as a HASHREF.

=cut

sub config {
    state $config = {};
}

my $stores = {};

=head2 default_store

Return the name of the default store.

=cut

sub default_store { 'default' }

=head2 store([NAME])

Return an instance of a store with name NAME or use the default store when no
name is provided.  The NAME is set in the configuration file. E.g.

 store:
  default:
   package: ElasticSearch
   options:
     index_name: blog
  test:
   package: Mock

In your program:

    # This will use ElasticSearch
    Catmandu->store->bag->each(sub {  ... });
    Catmandu->store('default')->bag->each(sub {  ... });
    # This will use Mock
    Catmandu->store('test')->bag->search(...);

=cut

sub store {
    my $self = shift;
    my $sym = check_string(shift || $self->default_store);

    $stores->{$sym} || do {
        if (my $cfg = $self->config->{store}{$sym}) {
            check_hash_ref($cfg);
            check_string(my $pkg = $cfg->{package});
            check_hash_ref(my $opts = $cfg->{options} || {});
            $opts = is_hash_ref($_[0])
                ? {%$opts, %{$_[0]}}
                : {%$opts, @_};
            $stores->{$sym} = require_package($pkg, 'Catmandu::Store')->new($opts);
        } else {
            require_package($sym, 'Catmandu::Store')->new(@_);
        }
    };
}

=head2 importer(NAME)

Return an instance of a Catmandu::Importer with name NAME (or the default 'JSON' when no name is given).
The NAME is set in the configuration file. E.g.

 importer:
  oai:
   package: OAI
    options:
     url: http://www.instute.org/oai/
  feed:
   package: Atom
    options:
     url: http://www.mysite.org/blog/atom

In your program:

Catmandu->importer('oai')->each(sub { ... } );
Catmandu->importer('oai', url => 'http://override')->each(sub { ... } );
Catmandu->importer('feed')->each(sub { ... } );

=cut

sub importer {
    my $self = shift;
    my $sym = check_string(shift);
    if (my $cfg = $self->config->{importer}{$sym}) {
        check_hash_ref($cfg);
        check_string(my $pkg = $cfg->{package});
        check_hash_ref(my $opts = $cfg->{options} || {});
        $opts = is_hash_ref($_[0])
            ? {%$opts, %{$_[0]}}
            : {%$opts, @_};
        require_package($pkg, 'Catmandu::Importer')->new($opts);
    } else {
        require_package($sym, 'Catmandu::Importer')->new(@_);
    }
}

=head2 exporter([NAME])

Return an instance of Catmandu::Exporter with name NAME (or the default 'JSON' when no name is given).
The NAME is set in the configuration file (see 'importer').

=cut

sub exporter {
    my $self = shift;
    my $sym = check_string(shift);
    if (my $cfg = $self->config->{exporter}{$sym}) {
        check_hash_ref($cfg);
        check_string(my $pkg = $cfg->{package});
        check_hash_ref(my $opts = $cfg->{options} || {});
        $opts = is_hash_ref($_[0])
            ? {%$opts, %{$_[0]}}
            : {%$opts, @_};
        require_package($pkg, 'Catmandu::Exporter')->new($opts);
    } else {
        require_package($sym, 'Catmandu::Exporter')->new(@_);
    }
}

=head2 export($data,[NAME])

Export data using a default or named exporter.

    Catmandu->export({ foo=>'bar'});

    my $importer = Catmandu::Importer::Mock->new;
    Catmandu->export($importer, 'YAML', file => '/my/file');
    Catmandu->export($importer, 'my_exporter');
    Catmandu->export($importer, 'my_exporter', foo => $bar);

=cut

sub export {
    my $self = shift;
    my $data = shift;
    my $exporter = $self->exporter(@_);
    is_hash_ref($data)
        ? $exporter->add($data)
        : $exporter->add_many($data);
    $exporter->commit;
    return;
}

=head2 export_to_string

Export data using a default or named exporter to a string.

    my $importer = Catmandu::Importer::Mock->new;
    my $yaml = Catmandu->export_to_string($importer, 'YAML');
    # is the same as
    my $yaml = "";
    Catmandu->export($importer, 'YAML', file => \$yaml);

=cut

sub export_to_string {
    my $self = shift;
    my $data = shift;
    my $sym  = shift;
    my %opts = is_hash_ref($_[0]) ? %{$_[0]} : @_;
    my $str  = "";
    my $exporter = $self->exporter($sym, %opts, file => \$str);
    is_hash_ref($data)
        ? $exporter->add($data)
        : $exporter->add_many($data);
    $exporter->commit;
    $str;
}

=head1 SEE ALSO

L<Catmandu::Introduction>

=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 CONTRIBUTORS

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

Christian Pietsch

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
