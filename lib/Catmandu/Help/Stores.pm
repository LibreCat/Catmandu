1;

=pod

=encoding utf8

=head1 Stores

Store are Catmandu packages to store Catmandu L<Items|Catmandu::Help::Items> in a
database. These databases need to be installed separately from Catmandu. Special
database such as MongoDB, ElasticSearch and CouchDB can work out-of-the-box with
hardly any configuration. For other databases such as Solr, MySQL, Postgres and
Oracle extra configuration steps are needed to define the database schemas.

Catmandu stores such as MongoDB, ElasticSearch and CouchDB can accept any type of
input. They are perfect tools to store the output of data conversions.

Without defining any database schema, JSON, YAML , MARC, Excel, CSV, OAI-PMH or
any other Catmandu supported format can be stored.

    $ catmandu import JSON to MongoDB --database_name test < data.json
    $ catmandu import YAML to MongoDB --database_name test < data.yml
    $ catmandu import MARC to MongoDB --database_name test < data.mrc
    $ catmandu import XLS to MongoDB --database_name test  < data.xls

Many Catmandu stores can be queried with their native query language:

    $ catmandu export MongoDB --database_name test --query '{"my.deep.field":"abc"}'

To delete data from a store the delete command can be used.

    # Delete everything
    $ catmandu delete MongoDB --database_name test
    # Delete record with _id = 1234 and _id = 1235
    $ catmandu delete MongoDB --database_name test --id 1234 --id 1235

Use the count command to show the size of a database.

    $ catmandu count MongoDB --database_name test

One important use-case for Catmandu is indexation of data in search engines such
as Solr. To do this, Solr needs to be configured for the fields you want to make
searchable. Your data collection can be indexed in the Solr engine by mapping the
fields in your data to the fields available in Solr.

    $ catmandu import MARC to Solr --fix marc2solr.fix < data.mrc

where marc2solr.fix is a Fix script containing all the fixes required to transform
your input data in the Solr format:

    # marc2solr.fix
    marc_map('008_/7-10','year')
    marc_map('020a','isbn.$append')
    marc_map('022a','issn.$append')
    marc_map('245a','title_short')
    .
    .
    .

In reality the Fix script will contain many mappings and data transformations to
clean data. See L<Example Fix Script|Catmandu::Help::ExampleFixScript> for a long
example of such a data cleaning in action.
