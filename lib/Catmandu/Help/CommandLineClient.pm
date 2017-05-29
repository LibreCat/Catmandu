1;

=pod

=encoding utf8

=head1 Command Line Client

Most of the Catmandu processing doesn't require you to write any code. With our
command line tools you can store data files into databases, index your data,
export data in various formats and provide basic data cleanup operations.

=head2 convert

The L<Catmandu::Cmd::convert> command is used to transfrom one format to another,
or to download data from the Internet. For example, to extract all titles from a
MARC record one can write:

    $ catmandu convert MARC to CSV --fix 'marc_map(245a,title); retain(title)' < data.mrc

In the example above, we import MARC and export it again as CSV while extracting
the 245a field from a record and deleting all the rest. With the convert command
one can transform data from one format to another.

Transform JSON to YAML:

    $ catmandu convert JSON to YAML < data.json

Transform YAML to JSON:

    $ catmandu convert YAML to JSON < data.json

Convert Excel to CSV:

    $ catmandu convert XLS to CSV < data.xls

The L<Fix|Catmandu::Help::FixLanguage> language can be used to extract the fields
from a input you are interested in.
Convert Excel to CSV and only keep the titles, authors, and year columns:

    $ catmandu convert XLS to CSV --fix 'retain(titles,authors,year)' < data.xls

In formats such as JSON or YAML the data can be deeply nested. All these fields
can be accessed and converted.

    $ catmandu convert JSON --fix 'upcase(my.nested.field.1)' < data.xls

In the example above a JSON input is converted by upcasing the field my that
contains a field nested that contains a field field that contains a list for
which the second item (indicated by 1) should be upcased.

The convert command can also be used to extract data from a database. For example
to download the Dublin Core data from the UGent institutional repository type:

    $ catmandu convert OAI --url http://biblio.ugent.be/oai

To get a CSV export of all identifiers in this OAI-PMH service type:

    $ catmandu convert OAI --url http://biblio.ugent.be/oai to CSV --fix 'retain(_id)'

Or a YAML file with all titles:

    $ catmandu convert OAI --url http://biblio.ugent.be/oai --set public to YAML --fix 'retain(title)'

=head2 import

The import command is used to import data into a database. Catmandu provides support
for NOSQL databases such as MongoDB, Elasticsearch and CouchDB which require
no preconfiguration before they can be used. There is also support for relational
databases such as Oracle, MySQL and Postgres via DBI or search engines like Solr
but they need to be configured first (databases, tables, schemas need to be created first).

Importing a JSON document into MongoDB database can be as simple as:

    $ catmandu import JSON  to MongoDB --database_name bibliography < books.json

Importing into a database can be done for every format that is supported by Catmandu.
For instance, MARC can be imported with this command:

    $ catmandu import MARC to MongoDB --database_name marc_data < data.mrc

Or, XLS:

    $ catmandu import XLS to MongoDB --database_name my_xls_data < data.xls

Even a download from a website can be directly stored into a database.

    $ catmandu import -v OAI --url http://biblio.ugent.be/oai to MongoDB --database_name oai_data

In the example above a copy of the institutional repository of Ghent University
was loaded into a MongoDB database. Use the option -v to see a progress report.

Before the data is imported a Fix can be applied to extract fields or transform
fields before they are stored into the database. For instance, we can extract
the publication year from a MARC import and store this as a separate year field:

    $ catmandu import MARC to MongoDB --database_name marc_data --fix 'marc_map("008/7-10",year)' < data.mrc
export

The export command is used to retreive data from a database. See the import command
above for a list of databases that are supported.

For instance we can export all the MARC records we have imported with this command:

    $ catmandu export MongoDB --database_name marc_data

In case we only need the title field from the marc records and want the results
in a CSV format we can add some fixes:

    $ catmandu export MongoDB --database_name marc_data to CSV --fix 'marc_map(245a,title); retain(title)'

Some database support a query syntax to query for records to be exported. For
instance, in the example above we extracted the year field form the MARC import.
This can be used to only export the records of a particular year:

    $ catmandu export MongoDB --database_name marc_data --query '{"year": "1971"}'

=head2 configuration

It is often handy to store the configuration options of importers, exporter and
stores into a file. This allows you to create shorter easier commands. To do this
a file C<catmandu.yml> needs to be created in your working directory with content like:

    ---
    importer:
      ghent:
         package: OAI
         options:
            url: http://biblio.ugent.be
            set: public
            handler: marcxml
            metadataPrefix: marc21
    store:
      ghentdb:
         package: MongoDB
         options:
            database_name: oai_data
            default_bag: data

When this file is available, an OAI-PMH harvest could be done with the shortened command:

    $ catmandu convert ghent

To store the ghent OAI-PMH import into the MongoDB database, one could write:

    $ catmandu import ghent to ghentdb

To extract the data from the database, one can write:

    $ catmandu export ghentdb
    
