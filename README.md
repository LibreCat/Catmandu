# NAME

Catmandu - a data toolkit

# DESCRIPTION

Importing, transforming, storing and indexing data should be easy.

Catmandu provides a suite of Perl modules to ease the import, storage,
retrieval, export and transformation of metadata records. Combine Catmandu
modules with web application frameworks such as PSGI/Plack, document stores
such as MongoDB and full text indexes such as Solr to create a rapid
development environment for digital library services such as institutional
repositories and search engines.

In the [http://librecat.org/|LibreCat](http://librecat.org/|LibreCat) project it is our goal to provide an 
open source set of programming components to build up digital libraries 
services suited to your local needs.

Read an in depth introduction into Catmandu programming at
[https://github.com/LibreCat/Catmandu/wiki/Introduction](https://github.com/LibreCat/Catmandu/wiki/Introduction).

# ONE STEP INSTALL

To install all Catmandu components in one easy step:

    cpan Task::Catmandu
    # or
    cpanm --interactive Task::Catmandu

or read our wiki for more installation hints:

    https://github.com/LibreCat/Catmandu/wiki/Install

# SYNOPSIS

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

    _path:
        foo:
            bar:
    baz: 1

will be loaded as

    foo:
      bar:
        baz: 1

See [Config::Onion](https://metacpan.org/pod/Config::Onion) for more information on how this works.

# METHODS

## log

Return the current logger (the [Log::Any::Adapter](https://metacpan.org/pod/Log::Any::Adapter) for category
[Catmandu::Env](https://metacpan.org/pod/Catmandu::Env)).

E.g. turn on logging in your application;

    package main;
    use Catmandu;
    use Log::Any::Adapter;
    use Log::Log4perl;

    Log::Log4perl::init('./log4perl.conf');
    Log::Any::Adapter->set('Log4perl');

    my $importer = Catmandu::Importer::JSON->new(...);
    ...

## default\_load\_path('/default/path')

Set the location of the default configuration file to a new path.

## load

Load all the configuration options in the catmandu.yml configuration file.

## load('/path', '/another/path')

Load all the configuration options stored at alternative paths.

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

Return an instance of [Catmandu::Store](https://metacpan.org/pod/Catmandu::Store) with name NAME or use the default store
when no name is provided.  The NAME is set in the configuration file. E.g.

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

## default\_fixer

Return the name of the default fixer.

## fixer(NAME)

Return an instance of [Catmandu::Fix](https://metacpan.org/pod/Catmandu::Fix) with name NAME (or 'default' when no
name is given).  The NAME is set in the config. E.g.

    fixer:
     default:
       - do_this()
       - do_that()

In your program:

    my $clean_data = Catmandu->fixer('cleanup')->fix($data);
    # or inline
    my $clean_data = Catmandu->fixer('do_this()', 'do_that()')->fix($data);
    my $clean_data = Catmandu->fixer(['do_this()', 'do_that()'])->fix($data);

## default\_importer

Return the name of the default importer.

## default\_importer\_package

Return the name of the default importer package if no
package name is given in the config or as a param.

## importer(NAME)

Return an instance of a [Catmandu::Importer](https://metacpan.org/pod/Catmandu::Importer) with name NAME
(or the default when no name is given).
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

# SEE ALSO

[https://github.com/LibreCat/Catmandu/wiki](https://github.com/LibreCat/Catmandu/wiki).

# AUTHOR

Nicolas Steenlant, `<nicolas.steenlant at ugent.be>`

# CONTRIBUTORS

Patrick Hochstenbach, `<patrick.hochstenbach at ugent.be>`

Vitali Peil, `vitali.peil at uni-bielefeld.de`

Christian Pietsch, `christian.pietsch at uni-bielefeld.de`

Dave Sherohman, `dave.sherohman at ub.lu.se`

# LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
