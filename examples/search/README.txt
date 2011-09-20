Catmandu search example
=======================

Step 1: start the Solr server
-----------------------------

    cd solr
    java -jar start.jar

Step 2: add data to the Solr index
----------------------------------

    bin/cmd data --from-importer OAI \
                 --from-url http://lup.lub.lu.se/oai \
                 --into-index Solr \

Catmandu::Importer::OAI imports oai_dc metadata from any OAI provider

Step 3: start Dancer
--------------------

start Dancer directly:

    bin/app

or with psgi/plack (http://plackperl.org):

    plackup --port 3000 bin/app

and point your browser to http://localhost:3000

Commandline examples
--------------------

    bin/cmd data --from-index Solr -q "subject:history" --into-exporter JSON --pretty
    bin/cmd data --from-index Solr -q "*" --limit 10 --start 10 --into-exporter YAML

data can also be copied into another Index or a Store
