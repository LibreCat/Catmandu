catmandu import -I CSV -s path=data/database.db export.csv

catmandu index -s path=data/database.db -t path=data/index

catmandu search -t path=data/index --query="local"

