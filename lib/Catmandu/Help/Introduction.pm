1;

=pod

=encoding utf8

=head1 Introduction

Catmandu is a command line tool to access and convert data from your digital library,
research services or any other open data sets. The toolkit was originally developed
as part of the L<LibreCat|https://github.com/LibreCat/Catmandu/wiki/LibreCat> project
and attracts now an international development team with many participating institutions.

Catmandu has the following features, one can:

  * download data via protocols such as OAI-PMH, SRU, SPARQL and Linked Data Fragments.
  * convert formats library format such as MARC, MODS, Dublin Core and but also others like JSON, YAML, XML, Excel and many more.
  * generate RDF and speak the Semantic Web.
  * index data into databases such as Solr, Elasticsearch and MongoDB.
  * use a simple L<Catmandu::Help::Fix> language to convert metadata into any format you like.

Catmandu is used in the LibreCat project to build institutional repositories and
search engines. Catmandu is used on the command line for quick and dirty reports
but also as part of larger programming projects processing millions of records per
day. For a short overview of use-cases, see our L<Homepage|http://librecat.org/use-cases.html>.

There are than 60 Catmandu projects available at L<GitHub|https://github.com/organizations/LibreCat>.
