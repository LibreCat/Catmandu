# View the contents of the Aleph dump mapped to your needs
#
# data/aleph.map contains the mapping from Aleph sequential to your own data model
#
catmandu convert -I Aleph -i map=data/aleph.map -o pretty=1 incoming/aleph.txt

#
# Create a new Aleph store
#
rm data/aleph.db
catmandu import -v -I Aleph -i map=data/aleph.map -s path=data/aleph incoming/aleph.txt
