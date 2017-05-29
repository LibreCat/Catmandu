1;

=pod

=encoding utf8

=head1 Concepts

To better make use of Catmandu is helps to first understand its B<core concepts>:

L<Items|Catmandu::Help::Items> are the basic unit of data processing in Catmandu.
Items can be read, stored, and accessed in many formats. An item can be a MARC
record or a RDF triple or one row in an Excel file.

L<Importers|Catmandu::Help::Importers>  are used to read items. There are importers
for MARC, JSON, YAML, CSV, Excel, and many other input formats. One can also
import from remote sources such as SPARQL, Atom and OAI-PMH endpoints.

L<Exporters|Catmandu::Help::Exporters>  are used to transform items back into JSON,
YAML, CSV, Excel or any format you like.

L<Stores|Catmandu::Help::Stores>  are database to store your data. With database
such MongoDB and ElasticSearch it becomes really, really easy to store quite
complicated, deeply nested, items.

L<Fixes|Catmandu::Help::Fixes> transforms items, transform the data into any
format you like. See Fix language and Fix packages for details.
