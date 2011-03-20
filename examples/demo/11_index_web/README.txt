
# Store the data and make sure we store the unique id in the _field
catmandu import -I CSV -s path=data/database.db --fix="copy_field($.id,'_id')" export.csv

# Index the data
catmandu index -s path=data/database.db -t path=data/index 

# Run the search engine
catmandu start Module::Search
