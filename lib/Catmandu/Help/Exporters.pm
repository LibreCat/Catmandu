1;

=pod

=encoding utf8

=head1 Exporters

Exporters are Catmandu packages to export data in specific format. See
L<Importers|Catmandu::Help::Importers> for the opposite action.

Some exporter such as JSON and YAML can handle any type of input. It doesn't matter
how the input is structured, it is always possible to create a JSON or YAML file.

Exporter are given after the to argument to the convert command

    $ catmandu convert OAI --url http://biblio.ugent.be/oai to JSON
    $ catmandu convert MARC to JSON
    $ catmandu convert XLS to JSON

For most exporters however, the input data needs to be structured in a specific
format. For instance, tabular formats such as Excel, CSV and TSV don't allow for
nested fields. In the example below, catmandu tried to convert a list into a
simple value which will fail:

    $ echo '{"colors":["red","green","blue"]}' | catmandu convert JSON to CSV
    colors
    ARRAY(0x7f8885a16a50)

The is an ARRAY output, indicating that the colors field is nested. To fix this,
a transformation needs to be provided:

    $ echo '{"colors":["red","green","blue"]}' | catmandu convert JSON to CSV --fix 'join_field(colors,",")'
    colors
    "red,green,blue"

MARC output should have an input in the Catmandu MARC format, RDF exports need
the aREF format, etc etc.

Exporter also accept options to configure the various kinds of exports. For instance, J
SON can be exporter in a array or line by line format

    $ catmandu convert MARC to JSON --array 1 < data.mrc
    $ catmandu convert MARC to JSON --line_delimited 1 < data.mrc
    $ catmandu convert MARC to JSON --pretty 1 < data.mrc

The L<Catmandu::Template> package can be used to generate any type of structured output
given an input using the L<Template> Toolkit language.

For instance, to create a JSON array of colors an echo command can used on Linux:

    $ echo '{"colors":["red","green","blue"]}'

To transform this JSON into XML, the Template exporter can be used with a template file
as a command line argument:

    $ echo '{"colors":["red","green","blue"]}' | catmandu convert JSON to Template --template `pwd`/xml.tt

and xml.tt like:

    <colors>
    [% FOREACH c IN colors %]
      <color>[% c %]</color>
    [% END %]
    </colors>

will produce:

    <colors>
      <color>red</color>
      <color>green</color>
      <color>blue</color>
    </colors>

Consult the manual pages of catmandu to see the output options of the different Exporters:

    $ catmandu help export JSON
    $ catmandu help export YAML
    $ catmandu help export CSV
