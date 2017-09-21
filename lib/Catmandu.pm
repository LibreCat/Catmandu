package Catmandu;

use Catmandu::Sane;

our $VERSION = '1.0604';

use Catmandu::Env;
use Catmandu::Util qw(:is);
use File::Spec;
use namespace::clean;
use Sub::Exporter::Util qw(curry_method);
use Sub::Exporter -setup => {
    exports => [
        config             => curry_method,
        log                => curry_method,
        store              => curry_method,
        fixer              => curry_method,
        importer           => curry_method,
        exporter           => curry_method,
        export             => curry_method,
        export_to_string   => curry_method,
        import_from_string => curry_method
    ],
    collectors => {'-load' => \'_import_load', ':load' => \'_import_load',},
};

sub _import_load {
    my ($self, $value, $data) = @_;
    if (is_array_ref $value) {
        $self->load(@$value);
    }
    else {
        $self->load;
    }
    1;
}

sub _env {
    my ($class, $env) = @_;
    state $loaded_env;
    $loaded_env = $env if defined $env;
    $loaded_env
        ||= Catmandu::Env->new(load_paths => $class->default_load_path);
}

sub log {$_[0]->_env->log}

sub default_load_path {    # TODO move to Catmandu::Env
    my ($class, $path) = @_;
    state $default_path;
    $default_path = $path if defined $path;
    $default_path //= do {
        my $script = File::Spec->rel2abs($0);
        my ($script_vol, $script_path, $script_name)
            = File::Spec->splitpath($script);
        my @dirs = grep length, File::Spec->splitdir($script_path);
        if ($dirs[-1] eq 'bin') {
            pop @dirs;
            File::Spec->catdir(File::Spec->rootdir, @dirs);
        }
        else {
            $script_path;
        }
    };
}

sub load {
    my $class = shift;
    my $paths = [@_ ? @_ : $class->default_load_path];
    my $env   = Catmandu::Env->new(load_paths => $paths);
    $class->_env($env);
    $class;
}

sub roots {
    $_[0]->_env->roots;
}

sub root {
    $_[0]->_env->root;
}

sub config {
    my ($class, $config) = @_;
    if ($config) {
        my $env = Catmandu::Env->new(load_paths => $class->_env->load_paths);
        $env->_set_config($config);
        $class->_env($env);
    }
    $class->_env->config;
}

sub default_store {$_[0]->_env->default_store}

sub store {
    my $class = shift;
    $class->_env->store(@_);
}

sub default_fixer {$_[0]->_env->default_fixer}

sub fixer {
    my $class = shift;
    $class->_env->fixer(@_);
}

sub default_importer {$_[0]->_env->default_importer}

sub default_importer_package {$_[0]->_env->default_importer_package}

sub importer {
    my $class = shift;
    $class->_env->importer(@_);
}

sub default_exporter {$_[0]->_env->default_exporter}

sub default_exporter_package {$_[0]->_env->default_exporter_package}

sub exporter {
    my $class = shift;
    $class->_env->exporter(@_);
}

sub export {
    my $class    = shift;
    my $data     = shift;
    my $exporter = $class->_env->exporter(@_);
    is_hash_ref($data) ? $exporter->add($data) : $exporter->add_many($data);
    $exporter->commit;
    return;
}

sub export_to_string {
    my $class    = shift;
    my $data     = shift;
    my $name     = shift;
    my %opts     = ref $_[0] ? %{$_[0]} : @_;
    my $str      = "";
    my $exporter = $class->_env->exporter($name, %opts, file => \$str);
    is_hash_ref($data) ? $exporter->add($data) : $exporter->add_many($data);
    $exporter->commit;
    $str;
}

sub import_from_string {
    my $class = shift;
    my $str   = shift;
    my $name  = shift;
    my %opts  = ref $_[0] ? %{$_[0]} : @_;
    $class->_env->importer($name, %opts, file => \$str)->to_array();
}

sub define_importer {
    my $class   = shift;
    my $name    = shift;
    my $package = shift;
    my $options = ref $_[0] ? $_[0] : {@_};
    $class->config->{importer}{$name}
        = {package => $package, options => $options};
}

sub define_exporter {
    my $class   = shift;
    my $name    = shift;
    my $package = shift;
    my $options = ref $_[0] ? $_[0] : {@_};
    $class->config->{exporter}{$name}
        = {package => $package, options => $options};
}

sub define_store {
    my $class   = shift;
    my $name    = shift;
    my $package = shift;
    my $options = ref $_[0] ? $_[0] : {@_};
    $class->config->{store}{$name}
        = {package => $package, options => $options};
}

sub define_fixer {
    my $class = shift;
    my $name  = shift;
    my $fixes = ref $_[0] ? $_[0] : [@_];
    $class->config->{fixer}{$name} = $fixes;
}

1;

__END__

=pod

=head1 NAME

Catmandu - a data toolkit

=head1 SYNOPSIS

    # From the command line

    # Convert data from one format to another
    $ catmandu convert JSON to CSV  < data.json
    $ catmandu convert CSV  to YAML < data.csv
    $ catmandu convert MARC to YAML < data.mrc

    # Fix data, add, delete, change fields
    $ catmandu convert JSON --fix 'move_field(title,my_title)' < data.json
    $ catmandu convert JSON --fix all_my_fixes.txt < data.json
    # Use a moustache preprocessor on the fix script
    $ catmandu convert JSON --fix all_my_fixes.txt --var opt1=foo --var opt2=bar < data.json

    # Import data into a database
    # Requires: Catmandu::MongoDB and Catmandu::ElasticSearch
    $ catmandu import YAML to MongoDB --database_name bibliography < data.yml
    $ catmandu import CSV to ElasticSearch --index_name mystuff < data.csv

    # Export data from a database
    # Requires: Catmandu::MongoDB and Catmandu::ElasticSearch
    $ catmandu export MongoDB --database_name bibliography to YAML > data.yml
    $ catmandu export ElasticSearch --index_name mystuff to CSV > data.csv

    # Copy data from one store to another
    $ catmandu copy MongoDB --database_name mydb to ElasticSearch --index_name mydb

    # Show the contents of catmandu.yml
    $ catmandu config

    # Count items in a store
    $ catmandu count test1

    # Delete items from store
    $ catmandu delete test1 --query 'title:"My Rabbit"'

    # run a fix script
    $ catmandu run myfixes.fix

    # or, create an executable fix script
    $ cat myfixes.fix
    #!/usr/local/bin/catmandu run
    do importer(OAI,url:"http://biblio.ugent.be/oai")
        retain(_id)
    end
    $ chmod 755 myfixes.fix
    $ ./myfixes.fix

    # From Perl
    use Catmandu;

    # If you have Catmandu::OAI and Catmandu::MongoDB installed
    my $importer = Catmandu->importer('OAI',url => 'https://biblio.ugent.be/oai')
    my $store    = Catmandu->store('MongoDB',database_name => 'test');

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

    $exporter->add_many( $fixer->fix($store) );
    $exporter->commit;

=head1 DESCRIPTION

Catmandu provides a command line client and a Perl API to ease the export (E)
transformation (T) and loading (L) of data into databases or data file, ETL in short.

Most of the daily work processing structured data can be done on the command line
executing the C<catmandu> command. With our catmandu command ETL processing is available
in a Perl context. Catmandu is different from other
ETL tools by its focus on command line processing with much support for dataformats
available in (academic) libraries: MARC, MODS, OAI and SRU. But, also generic formats such
as JSON, YAML, CVS, Excel, XML, RDF, Atom are supported.

Read :

=over

=item  * L<Catmandu::Introduction> for a primer on the command line capabilities of Catmandu.

=item  * L<Catmandu::Importer> for the basics of importing

=item  * L<Catmandu::Fix> for the basics of transformations

=item  * L<Catmandu::Exporter> for the basics of exporting

=item  * L<Catmandu::Store> for the basics of storing information

=item  * Or, visit our website at L<http://librecat.org/> and our blog L<https://librecatproject.wordpress.com/>
    for many tutorials

=back

The documentation below describes the methods available when including Catmandu as
part of a Perl script. For an overview of the command line tool itself read the
documentation on L<catmandu>.

=head1 USE

To include Catmandu in a Perl script it should be loaded with a C<use> command:

    use Catmandu;

By default no methods are imported into the Perl context. To import all or some Catmandu methods,
provide them as a list to the C<use> command:

    use Catmandu -all;
    use Catmandu qw(config store exporter);

Catmandu can load configuration options for exports, importers, fixers via configuration
files (see the CONFIG section below). When adding the --load option (optionally with a path) to the
C<use> command, these configuration files will be loaded at the start of your script.

    use Catmandu -load;
    use Catmandu --load => ['/my/config/directory'];

    # or use all the options
    use Catmandu -all -load => [qw(/config/path' '/another/config/path)];

=head1 CLASS METHODS

=head2 log

Return the current L<Log::Any> logger.

    use Catmandu;
    use Log::Any::Adapter;
    use Log::Log4perl;

    Log::Any::Adapter->set('Log4perl'); # requires Log::Any::Adapter::Log4perl
    Log::Log4perl::init('./log4perl.conf');

    my $logger = Catmandu->log;
    $logger->info("Starting main program");

with log4perl.conf like:

    # Send a copy of all logging messages to STDERR
    log4perl.rootLogger=DEBUG,STDERR

    # Logging specific for your main program
    log4perl.category.myprog=INFO,STDERR

    # Logging specific for on part of Catmandu
    log4perl.category.Catmandu::Fix=DEBUG,STDERR

    # Where to send the STDERR output
    log4perl.appender.STDERR=Log::Log4perl::Appender::Screen
    log4perl.appender.STDERR.stderr=1
    log4perl.appender.STDERR.utf8=1

    log4perl.appender.STDERR.layout=PatternLayout
    log4perl.appender.STDERR.layout.ConversionPattern=%d [%P] - %p %l time=%r : %m%n

=head2 default_load_path(['/default/path'])

Returns the default location where L<Catmandu> looks for configuration and lib
when called with no argument. Sets the default location if a path is given.
The default load path is the script directory or it's parent if the script
directory is C<bin>.

=head2 load

Load all the configuration options in the catmandu.yml configuration file.
See CONFIG below for extended examples of configuration options.

=head2 load('/path', '/another/path')

Load all the configuration options stored at alternative paths.

A load path C<':up'> will search upwards from your program for configuration.

See CONFIG below for extended examples of configuration options.

=head2 roots

Returns an ARRAYREF of paths where configuration was found. Note that this list
is empty before C<load>.

=head2 root

Returns the first path where configuration was found. Note that this is
C<undef> before C<load>.

=head2 config

Returns the current configuration as a HASHREF.

=head2 config($config)

Set a new configuration and reload the environment.

=head2 default_store

Return the name of the default store.

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

=head2 default_fixer

Return the name of the default fixer.

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

=head2 default_importer

Return the name of the default importer.

=head2 default_importer_package

Return the name of the default importer package if no
package name is given in the config or as a param.

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

=head2 default_exporter

Return the name of the default exporter.

=head2 default_exporter_package

Return the name of the default exporter package if no
package name is given in the config or as a param.

=head2 exporter([NAME])

Return an instance of L<Catmandu::Exporter> with name NAME (or the default when
no name is given).  The NAME is set in the configuration file (see 'importer').

=head2 export($data,[NAME])

Export data using a default or named exporter or exporter instance.

    Catmandu->export({ foo=>'bar'});

    my $importer = Catmandu::Importer::Mock->new;
    Catmandu->export($importer, 'YAML', file => '/my/file');
    Catmandu->export($importer, 'my_exporter');
    Catmandu->export($importer, 'my_exporter', exporter_option => '...' , ...);
    Catmantu->export($importer, Catmandu::Exporter::YAML->new);

=head2 export_to_string

Export data using a default or named exporter to a string.

    my $importer = Catmandu::Importer::Mock->new;
    my $yaml = Catmandu->export_to_string($importer, 'YAML');
    # is the same as
    my $yaml = "";
    Catmandu->export($importer, 'YAML', file => \$yaml);

=head2 import_from_string

Import data from a string using a default or named importer.
Return value should be an array of hashes.

    my $json = qq([{"name":"Nicolas"}]);
    {
        my $record = Catmandu->import_from_string( $json, "JSON" );
    }
    # is the same as
    {
        my $record = Catmandu->importer('JSON', file => \$json)->to_array()
    }

=head2 define_importer

Configure a new named importer.

    Catmandu->define_importer(books => CSV => (fields => 'title,author,publisher'));
    Catmandu->importer(books => (file => 'mybooks.csv'))->each(sub {
        my $book = shift;
        say $book->{title};
    });

    # this is equivalent to

    Catmandu->config->{importer}{books} = {
        package => 'CSV',
        options => {
            fields => 'title,author,publisher',
        },
    }

=head2 define_exporter

Configure a new named exporter.

    Catmandu->define_exporter('books', 'CSV', fix => 'capitalize(title)');
    my $csv = Catmandu->export_to_string({title => 'nexus'}, 'books');

    # this is equivalent to

    Catmandu->config->{exporter}{books} = {
        package => 'CSV',
        options => {
            fix => 'capitalize(title)',
        },
    }

=head2 define_store

Configure a new named store.

    Catmandu->define_store(mydb => MongoDB => (database_name => 'mydb'));
    Catmandu->store->bag('books')->get(1234);

    # this is equivalent to

    Catmandu->config->{store}{mydb} = {
        package => 'MongoDB',
        options => {
            database_name => 'mydb',
        },
    }

=head2 define_fixer

Configure a new named fixer.

    Catmandu->define_fixer('cleanup', [
        'trim(title)',
        'capitalize(title)',
        'remove_field(junk)',
        # ...
    ]);
    Catmandu->fixer('cleanup')->fix($record);

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

=item import_from_string

Same as C<< Catmandu->import_from_string >>.

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

L<http://librecat.org/Catmandu/>

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

Magnus Enger, C<< magnus at enger.priv.no >>

Nicolas Franck, C<< nicolas.franck at ugent.be >>

Patrick Hochstenbach, C<< patrick.hochstenbach at ugent.be >>

Vitali Peil, C<< vitali.peil at uni-bielefeld.de >>

Christian Pietsch, C<< christian.pietsch at uni-bielefeld.de >>

Dave Sherohman, C<< dave.sherohman at ub.lu.se >>

Jakob Voss, C<< nichtich at cpan.org >>

Snorri Briem, C<< snorri.briem at ub.lu.se >>

Johann Rolschewski, C<< jorol at cpan.org >>

Pieter De Praetere, C<< pieter.de.praetere at helptux.be >>

Doug Bell

Upsana, C<< me at upasana.me >>

Stefan Weil

Tom Hukins

=head1 QUESTIONS, ISSUES & BUG REPORTS

For any questions on the use of our modules please join our mailing list at:

    librecat-dev@lists.uni-bielefeld.de

or send in your bug reports or feature requests to our issue tracker at:

    https://github.com/LibreCat/Catmandu/issues

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
