# View the contents of the Fedora dump mapped to your needs
#
catmandu convert -I Fedora  -o pretty=1 incoming/fedora.txt

#
# Create a new Aleph store
#
rm data/fedora.db
catmandu import -v -I Fedora -s path=data/fedora.db incoming/fedora.txt
