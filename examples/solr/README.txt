##############################################################################
# 1) Start the SOLR index daemon

cd engine
java -jar start.jar

# This shoud display something like:
#
# 2010-12-06 15:36:29.468::INFO:  Started SocketConnector @ 0.0.0.0:8983
#
# on success. Now you can connect with a web browser to the address
#
# http://localhost:8983/solr
#
# To view the administrative interface to the SOLR full-text engine
#

##############################################################################
# 2) Add some data in a content store

# We use the UGent Biblio as an example which provides a specialized importer
#

catmandu import -v -I Luur -s file=data/biblio.db -i http://biblio.ugent.be/oai/

# You can type Ctr-c to import only a handful of documents as example

# To view the content of this store use:
# 
# catmandu export -o pretty=1 -s file=data/biblio.db
#


##############################################################################
# 3) Define which fields you want to index

# The file engine/solr/conf/schema.xml contains the SOLR configurtion of fields
# that are available for indexing. In our example we have:
#
# - _id
# - type
# - title
# - jtitle
# - department
# - author
# - year
# - classification
# - local
# - text  (default catch all)
#
# The file data/biblio.idx contains how fields from the content store are mapped
# to these index fields. Each line contains a path to an record field and a 
# index where it should be stored. E.g.
#
# $.title    title
#
# The 'title' field needs to be indexed in the 'title' index
#
# The default should be ok for now.
#


##############################################################################
# 4) Index the data

catmandu index -T Solr -s path=data/biblio.db data/biblio.idx


##############################################################################
# 5) Start the web-front end

catmandu start


##
# Remark:
#   The catmandu.yml makes sure you'll use most of the configuration, templates, etc from 
#   the 'search' example project
