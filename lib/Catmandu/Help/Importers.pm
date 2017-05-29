1;

=pod

=encoding utf8

=head1 Importers

Importers are Catmandu packages to read a specific data format. Catmandu provides
importers for MARC, JSON, YAML, CSV, Excel, and many other input formats. One
can also import from remote sources for instance via protocols such as SPARQL
and OAI-PMH.

The name of a Catmandu importer should be provided as first argument to the
convert command.

Read JSON input:

    $ catmandu convert JSON

Read YAML input

    $ catmandu convert YAML

Read MARC input

    $ catmandu convert MARC

The Importer accepts configurable options. The following arguments to the MARC
importer are currently supported:

  * USMARC (use ISO as an alias)
  * MicroLIF
  * MARCMaker
  * MiJ (for MARC-in-JSON)
  * XML (for MARCXML)
  * RAW
  * Lint
  * ALEPHSEQ(for Aleph Sequential)

Read MARC-XML input

    $ catmandu convert MARC --type XML < marc.xml

Read Aleph sequential input

    $ catmandu convert MARC --type ALEPHSEQ < marc.txt

Read more about the configuration options of importers by reading their manual pages:

    $ catmandu help import JSON
    $ catmandu help import YAML
