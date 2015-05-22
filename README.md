# NAME

Catmandu - a data toolkit

# SYNOPSIS

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

# DESCRIPTION

Importing, transforming, storing and indexing data should be easy.

Catmandu provides a suite of Perl modules to ease the import, storage,
retrieval, export and transformation of metadata records. Combine Catmandu
modules with web application frameworks such as PSGI/Plack, document stores
such as MongoDB and full text indexes such as Solr to create a rapid
development environment for digital library services such as institutional
repositories and search engines.

In the [http://librecat.org/](http://librecat.org/) project it is our goal to provide an
open source set of programming components to build up digital libraries
services suited to your local needs.

Read an in depth introduction into Catmandu programming at
[https://github.com/LibreCat/Catmandu/wiki/Introduction](https://github.com/LibreCat/Catmandu/wiki/Introduction).

# INSTALLATION

To install Catmandu just run:

    cpanm Catmandu

To install a whole bunch of Catmandu\* modules run

    cpanm --interactive Task::Catmandu

Read our documentation for more installation hints and OS specific requirements:

http://librecat.org/Catmandu/#installation

# METHODS

## log

Return the current logger (the [Log::Any::Adapter](https://metacpan.org/pod/Log::Any::Adapter) for category
[Catmandu::Env](https://metacpan.org/pod/Catmandu::Env)). See [Log::Any#Logging](https://metacpan.org/pod/Log::Any#Logging) for how to send messages to the
logger. Read our [https://github.com/LibreCat/Catmandu/wiki/Cookbook](https://github.com/LibreCat/Catmandu/wiki/Cookbook)
"See some debug messages" for some hints on logging.

## default\_load\_path('/default/path')

Set the location of the default configuration file to a new path.

## load

Load all the configuration options in the catmandu.yml configuration file.
See CONFIG below for extended examples of configuration options.

## load('/path', '/another/path')

Load all the configuration options stored at alternative paths.

A load path `':up'` will search upwards from your program for configuration.

See CONFIG below for extended examples of configuration options.

## roots

Returns an ARRAYREF of paths where configuration was found. Note that this list
is empty before `load`.

## root

Returns the first path where configuration was found. Note that this is
`undef` before `load`.

## config

Returns the current configuration as a HASHREF.

## default\_store

Return the name of the default store.

## store(\[NAME\])

Return an instance of [Catmandu::Store](https://metacpan.org/pod/Catmandu::Store). The NAME is a name of a [Catmandu::Store](https://metacpan.org/pod/Catmandu::Store) or the
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

## default\_fixer

Return the name of the default fixer.

## fixer(NAME)

## fixer(FIX,FIX)

## fixer(\[FIX\])

Return an instance of [Catmandu::Fix](https://metacpan.org/pod/Catmandu::Fix). NAME can be the name of a fixer section
in a catmandu.yml file. Or, one or more [Catmandu::Fix](https://metacpan.org/pod/Catmandu::Fix)-es can be provided inline.

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

## default\_importer

Return the name of the default importer.

## default\_importer\_package

Return the name of the default importer package if no
package name is given in the config or as a param.

## importer(NAME)

Return an instance of [Catmandu::Importer](https://metacpan.org/pod/Catmandu::Importer). The NAME is a name of a [Catmandu::Importer](https://metacpan.org/pod/Catmandu::Importer) or the
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

## default\_exporter

Return the name of the default exporter.

## default\_exporter\_package

Return the name of the default exporter package if no
package name is given in the config or as a param.

## exporter(\[NAME\])

Return an instance of [Catmandu::Exporter](https://metacpan.org/pod/Catmandu::Exporter) with name NAME (or the default when
no name is given).  The NAME is set in the configuration file (see 'importer').

## export($data,\[NAME\])

Export data using a default or named exporter.

    Catmandu->export({ foo=>'bar'});

    my $importer = Catmandu::Importer::Mock->new;
    Catmandu->export($importer, 'YAML', file => '/my/file');
    Catmandu->export($importer, 'my_exporter');
    Catmandu->export($importer, 'my_exporter', foo => $bar);

## export\_to\_string

Export data using a default or named exporter to a string.

    my $importer = Catmandu::Importer::Mock->new;
    my $yaml = Catmandu->export_to_string($importer, 'YAML');
    # is the same as
    my $yaml = "";
    Catmandu->export($importer, 'YAML', file => \$yaml);

# EXPORTS

- config

    Same as `Catmandu->config`.

- store

    Same as `Catmandu->store`.

- importer

    Same as `Catmandu->importer`.

- exporter

    Same as `Catmandu->exporter`.

- export

    Same as `Catmandu->export`.

- export\_to\_string

    Same as `Catmandu->export_to_string`.

- fixer

    Same as `Catmandu->fixer`.

- log

    Same as `Catmandu->log`.

- -all/:all

    Import everything.

- -load/:load

        use Catmandu -load;
        use Catmandu -load => [];
        # is the same as
        Catmandu->load;

        use Catmandu -load => ['/config/path'];
        # is the same as
        Catmandu->load('/config/path');

# CONFIG

Catmandu configuration options can be stored in files in the root directory of
your programming project. The file can be YAML, JSON or Perl and is called
`catmandu.yml`, `catmandu.json` or `catmandu.pl`. In this file you can set
the default Catmandu stores and exporters to be used. Here is an example of a
`catmandu.yml` file:

    store:
      default:
        package: ElasticSearch
        options:
          index_name: myrepository

    exporter:
      default:
        package: YAML

## Split config

For large configs it's more convenient to split the config into several files.
You can do so by having multiple config files starting with catmandu\*.

    catmandu.general.yml
    catmandu.db.yml
    ...

Split config files are processed and merged by [Config::Onion](https://metacpan.org/pod/Config::Onion).

## Deeply nested config structures

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

See [Config::Onion](https://metacpan.org/pod/Config::Onion) for more information on how this works.

# SEE ALSO

- documentation

    [http://librecat.org/Catmandu/](http://librecat.org/Catmandu/)

- command line client

    [catmandu](https://metacpan.org/pod/catmandu)

- core modules

    [Catmandu::Importer](https://metacpan.org/pod/Catmandu::Importer)
    [Catmandu::Exporter](https://metacpan.org/pod/Catmandu::Exporter),
    [Catmandu::Store](https://metacpan.org/pod/Catmandu::Store),
    [Catmandu::Fix](https://metacpan.org/pod/Catmandu::Fix),
    [Catmandu::Iterable](https://metacpan.org/pod/Catmandu::Iterable)

- install all modules

    [Task::Catmandu](https://metacpan.org/pod/Task::Catmandu)

- extended features

    [Catmandu::Validator](https://metacpan.org/pod/Catmandu::Validator)

# AUTHOR

Nicolas Steenlant, `<nicolas.steenlant at ugent.be>`

# CONTRIBUTORS

Magnus Enger, `magnus at enger.priv.no`

Nicolas Franck, `nicolas.franck at ugent.be`

Patrick Hochstenbach, `patrick.hochstenbach at ugent.be`

Vitali Peil, `vitali.peil at uni-bielefeld.de`

Christian Pietsch, `christian.pietsch at uni-bielefeld.de`

Dave Sherohman, `dave.sherohman at ub.lu.se`

Jakob Voss, `nichtich at cpan.org`

# LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
