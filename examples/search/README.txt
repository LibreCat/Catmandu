Run the server: catmandu start 

Fetch data from SBCAT: catmandu convert -I Luur -o pretty=1 http://biblio.ugent.be/oai/

Import data from SBCAT: catmandu import -v -I Luur -s file=data/biblio.db http://biblio.ugent.be/oai/

Index data from SBCAT: catmandu index -t path=data/biblio -s data/biblio.db
