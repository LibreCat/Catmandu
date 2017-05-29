1;

=pod

=encoding utf8

=head1 Items

An B<item> is the basic unit of data processing in Catmandu. Items are data
structures build of key-value-pairs (aka objects), lists (aka arrays), strings,
numbers, and null-values. All items can be expressed in JSON and YAML, among
other formats.

Internally all data processing by Catmandu is using a generic data format not
unlike JSON. If one imports MARC, XML, Excel, OAI-PMH, SPARQL, data from a
database or any other format, everything can be expressed as JSON.

For example:

  * JSON/YAML - when importing a large JSON/YAML collections as an array, every item is a Catmandu item.
  * Text - for text import every line of text is one Catmandu item.
  * MARC - when importing MARC data, every record in a MARC file is one Catmandu item.
  * XLS,CSV - for tabular formats such as Excel, CSV and TSV, each row in a table is one Catmandu item
  * RDF - for linked data formats such as RDF/XML, RDF/nTriples, RDF/Turtle each triple is one Catmandu item
  * SPARQL - for a result set of a SPARQL or LDF query, every result (with the variable bindings) is one Catmandu item
  * MongoDB,ElasticSearch,Solr,DBI - for databases every record in the database is one Catmandu item

To transform items with the L<Fix Language|Catmandu::Help::FixLanguage> one points to the
fields in items with a JSONPath expression (Catmandu uses an extension of JSONPath actually).
The fixes provided to a catmandu command operate on all individual items.

For instance, the command below will upcase the publisher field for every item (row)
in the data.xls file:

    $ catmandu convert XLS --fix 'upcase(publisher)' < data.xls

This command will select only the JSON items that contain 'Tsjechov' in a nested authors field:

    $ catmandu convert XLS --fix 'select any_match(authors.*,"Tsjechov.*")' < data.json

This command will delete all the uppercase A characters from a Text file:

    $ catmandu convert Text to Text --fix 'replace_all(A,"")' < data.txt

To see the internal representation of a MARC file in Catmandu, transform it for instance to YAML

    $ catmandu convert MARC to YAML < data.mrc

One will see that a MARC record is treated as an array of arrays for each item.
