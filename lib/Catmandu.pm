package Catmandu;

use Catmandu::Sane;
use Catmandu::Env;
use Catmandu::Util qw(:is);
use File::Spec;

our $VERSION = '0.9208';

=head1 NAME

Catmandu - a data toolkit

=head1 SYNOPSIS

    use Catmandu -all;
    use Catmandu qw(config store);
    use Catmandu -load; # loads default configuration file
    use Catmandu -all -load => [qw(/config/path' '/another/config/path)];

    # If you have Catmandu::OAI and Catmandu::MongoDB installed
    my $importer = Catmandu->importer('OAI',url => 'https://biblio.ugent.be/oai')
    my $store    = Catmandu->exporter('MongoDB',database_name => 'test');

    # Import all the OAI records into MongoDB
    $store->add_many($importer);

    # Export all the MongoDB records to YAML and apply some fixes
    # myfixes.txt:
    #   upcase(title.*)
    #   remove_field(_metadata)
    #   join_field(creator,'; ')
    #   join_field(subject,'-- ')
    my $fixer    = Catmandu->fixer('myfixes.txt');
    my $exporter = Catmandu->exporter('YAML'); 

    $exporter->add_many(
        $fixer->fix($store)
    );
    $exporter->commit;

    # Or be very lazy and do this via the command line
    $ catmandu import OAI --url https://biblio.ugent.be/oai to MongoDB --database_name test
    $ catmandu export MongoDB --database_name test --fix myfixes.txt to YAML

=head1 DESCRIPTION

Importing, transforming, storing and indexing data should be easy.

Catmandu provides a suite of Perl modules to ease the import, storage,
retrieval, export and transformation of metadata records. Combine Catmandu
modules with web application frameworks such as PSGI/Plack, document stores
such as MongoDB and full text indexes such as Solr to create a rapid
development environment for digital library services such as institutional
repositories and search engines.

In the L<http://librecat.org/> project it is our goal to provide an 
open source set of programming components to build up digital libraries 
services suited to your local needs.

Read an in depth introduction into Catmandu programming at
L<https://github.com/LibreCat/Catmandu/wiki/Introduction>.

=head1 ONE STEP INSTALL

To install all Catmandu components in one step:

    cpan Task::Catmandu
    # or
    cpanm --interactive Task::Catmandu

Read our wiki for more installation hints:

 https://github.com/LibreCat/Catmandu/wiki/Install

=cut
use Sub::Exporter::Util qw(curry_method);
use Sub::Exporter -setup => {
    exports => [config   => curry_method,
                log      => curry_method,
                store    => curry_method,
                fixer    => curry_method,
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

sub _env {
    my ($class, $env) = @_;
    state $loaded_env;
    $loaded_env = $env if defined $env;
    $loaded_env ||= Catmandu::Env->new(load_paths => $class->default_load_path);
}

=head1 METHODS

=head2 log

Return the current logger (the L<Log::Any::Adapter> for category
L<Catmandu::Env>). See L<Log::Any#Logging> for how to send messages to the
logger. Read our L<https://github.com/LibreCat/Catmandu/wiki/Cookbook> 
"See some debug messages" for some hints on logging.

=cut

sub log { $_[0]->_env->log }

=head2 default_load_path('/default/path')

Set the location of the default configuration file to a new path.

=cut

sub default_load_path { # TODO move to Catmandu::Env
    my ($class, $path) = @_;
    state $default_path;
    $default_path = $path if defined $path;
    $default_path //= do {
        my $script = File::Spec->rel2abs($0);
        my ($script_vol, $script_path, $script_name) = File::Spec->splitpath($script);
        my @dirs = grep length, File::Spec->splitdir($script_path);
        if ($dirs[-1] eq 'bin') {
            pop @dirs;
            File::Spec->catdir(File::Spec->rootdir, @dirs);
        } else {
            $script_path;
        }
    };
}

=head2 load

Load all the configuration options in the catmandu.yml configuration file.
See CONFIG below for extended examples of configuration options.

=head2 load('/path', '/another/path')

Load all the configuration options stored at alternative paths.

A load path C<':up'> will search upwards from your program for configuration.

See CONFIG below for extended examples of configuration options.

=cut

sub load {
    my $class = shift;
    my $paths = [@_ ? @_ : $class->default_load_path];
    my $env = Catmandu::Env->new(load_paths => $paths);
    $class->_env($env);
    $class;
}

=head2 roots

Returns an ARRAYREF of paths where configuration was found. Note that this list
is empty before C<load>.

=cut

sub roots {
    $_[0]->_env->roots;
}

=head2 root

Returns the first path where configuration was found. Note that this is
C<undef> before C<load>.

=cut

sub root {
    $_[0]->_env->root;
}

=head2 config

Returns the current configuration as a HASHREF.

=cut

sub config {
    $_[0]->_env->config;
}

=head2 default_store

Return the name of the default store.

=cut

sub default_store { $_[0]->_env->default_store }

=head2 store([NAME])

Return an instance of L<Catmandu::Store>. The NAME is a name of a L<Catmandu::Store> or the
name of a store configured in a catmandu.yml configuration file. When no NAME is given, the
'default' store in the configuration file will be used.

E.g. if the configuration file 'catmandu.yml' contains:

 store:
  default:
   package: ElasticSearch
   options:
     index_name: blog
  test:
   package: Mock

then in your program:

    # This will use ElasticSearch
    my $store = Catmandu->store('ElasticSearch', index_name => 'blog');

    # or because we have a 'default' set in the configuration file
    
    my $store = Catmandu->store('default');

    # or because 'default' will be used when no name was provided

    my $store = Catmandu->store;

    # This will use Mock
    my $store = Catmandu->store('test');

Configuration settings can be overwritten by the store command:

  my $store2 = Catmandu->store('default', index_name => 'test2');

=cut

sub store {
    my $class = shift;
    $class->_env->store(@_);
}

=head2 default_fixer

Return the name of the default fixer.

=cut

sub default_fixer { $_[0]->_env->default_fixer }

=head2 fixer(NAME)

=head2 fixer(FIX,FIX)

=head2 fixer([FIX])

Return an instance of L<Catmandu::Fix>. NAME can be the name of a fixer section 
in a catmandu.yml file. Or, one or more L<Catmandu::Fix>-es can be provided inline.

E.g. if the configuration file 'catmandu.yml' contains:

 fixer:
  default:
    - do_this()
    - do_that()

then in your program al these lines below will create the same fixer:

    my $fixer = Catmandu->fixer('do_this()', 'do_that()');
    my $fixer = Catmandu->fixer(['do_this()', 'do_that()']);
    my $fixer = Catmandu->fixer('default');
    my $fixer = Catmandu->fixer(); # The default name is 'default'

FIX-es can be also written to a Fix script. E.g. if myfixes.txt contains:

 do_this()
 do_that()

then the above code will even be equivalent to:

   my $fixer = Catmandu->fixer('myfixes.txt');

=cut

sub fixer {
    my $class = shift;
    $class->_env->fixer(@_);
}

=head2 default_importer

Return the name of the default importer.

=cut

sub default_importer { $_[0]->_env->default_importer }

=head2 default_importer_package

Return the name of the default importer package if no
package name is given in the config or as a param.

=cut

sub default_importer_package { $_[0]->_env->default_importer_package }

=head2 importer(NAME)

Return an instance of L<Catmandu::Importer>. The NAME is a name of a L<Catmandu::Importer> or the
name of a importer configured in a catmandu.yml configuration file. When no NAME is given, the
'default' importer in the configuration file will be used.

E.g. if the configuration file 'catmandu.yml' contains:

  importer:
    default:
      package: OAI
      options:
        url: http://www.instute.org/oai/

then in your program all these lines will be equivalent:

  my $importer = Catmandu->importer('OAI', url => 'http://www.instute.org/oai/');
  my $importer = Catmandu->importer('default');
  my $importer = Catmandu->importer(); # The default name is 'default'

Configuration settings can be overwritten by the importer command:

  my $importer2 = Catmandu->importer('default', url => 'http://other.institute.org');

=cut

sub importer {
    my $class = shift;
    $class->_env->importer(@_);
}

=head2 default_exporter

Return the name of the default exporter.

=cut

sub default_exporter { $_[0]->_env->default_exporter }

=head2 default_exporter_package

Return the name of the default exporter package if no
package name is given in the config or as a param.

=cut

sub default_exporter_package { $_[0]->_env->default_exporter_package }

=head2 exporter([NAME])

Return an instance of L<Catmandu::Exporter> with name NAME (or the default when
no name is given).  The NAME is set in the configuration file (see 'importer').

=cut

sub exporter {
    my $class = shift;
    $class->_env->exporter(@_);
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
    my $class = shift;
    my $data = shift;
    my $exporter = $class->_env->exporter(@_);
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
    my $class = shift;
    my $data = shift;
    my $name = shift;
    my %opts = ref $_[0] ? %{$_[0]} : @_;
    my $str = "";
    my $exporter = $class->_env->exporter($name, %opts, file => \$str);
    is_hash_ref($data)
        ? $exporter->add($data)
        : $exporter->add_many($data);
    $exporter->commit;
    $str;
}

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

=item fixer

Same as C<< Catmandu->fixer >>.

=item log

Same as C<< Catmandu->log >>.

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

=head1 CONFIG

Catmandu configuration options can be stored in files in the root directory of
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

For large configs it's more convenient to split the config into several files.
You can do so by having multiple config files starting with catmandu*.

    catmandu.general.yml
    catmandu.db.yml
    ...

Split config files are processed and merged by L<Config::Onion>.

=head2 Deeply nested config structures

Config files can indicate a path under which their keys will be nested. This
makes your configuration more readable by keeping indentation to a minimum.

A config file containing

    _prefix:
        foo:
            bar:
    baz: 1

will be loaded as

    foo:
      bar:
        baz: 1

See L<Config::Onion> for more information on how this works.

=head1 SEE ALSO

=over 4

=item documentation

L<https://github.com/LibreCat/Catmandu/wiki>

=item command line client

L<catmandu>

=item core modules

L<Catmandu::Importer>
L<Catmandu::Exporter>,
L<Catmandu::Store>,
L<Catmandu::Fix>,
L<Catmandu::Iterable>

=item extended features

L<Catmandu::Validator>

=back

=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 CONTRIBUTORS

Nicolas Franck, C<< nicolas.franck at ugent.be >>

Patrick Hochstenbach, C<< patrick.hochstenbach at ugent.be >>

Vitali Peil, C<< vitali.peil at uni-bielefeld.de >>

Christian Pietsch, C<< christian.pietsch at uni-bielefeld.de >>

Dave Sherohman, C<< dave.sherohman at ub.lu.se >>

Jakob Voss, C<< nichtich at cpan.org >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
