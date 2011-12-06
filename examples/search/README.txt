Catmandu search example
=======================

Step 1: start the Solr server
-----------------------------

    cd solr
    java -jar start.jar

Step 2: add data to the Solr index
----------------------------------

    bin/cmd data --from-importer OAI \
                 --from-url http://biblio.ugent.be/oai \
                 --into-store search \
                 --into-bag example \

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

    bin/cmd data --from-store search --from-bag example --query "subject:history" --into-exporter JSON
    bin/cmd data --from-store search --from-bag example --start 10 --total 10 --into-exporter YAML

data can also be copied into another Bag

    bin/cmd data --from-store search --from-bag example --into-store ...
