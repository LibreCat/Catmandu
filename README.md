# NAME

Catmandu::Introdction - a Catmandu HOW TO

# Introduction

Catmandu is a data processing toolkit developed as part of the [LibreCat](http://librecat.org) project. 
Catmandu provides a command line client and a suite of tools to ease the import, storage, retrieval, 
export and transformation of data. For instance, to transform a CSV file into JSON use the
command:

    $ catmandu convert JSON to CSV < data.json

Or, to store a YAML file into an ElasticSearch database type:

    $ catmandu import YAML to ElasticSearch --index_name demo < test.yml

To export all the data from an Solr search engine into JSON type:

    $ catmandu export Solr --url http://localhost:8983/solr to JSON

With Catmandu one can import OAI-PMH records in your application:

    $ catmandu convert OAI --url http://biblio.ugent.be/oai --set allFtxt

and export records into formats such as JSON, YAML, CSV, XLS, RDF and many more.

Catmandu also provides a small scripting language to manipulate data, extract parts of your dataset and
transform records. For instance, rename fields  with the 'move\_field' command:

    $ catmandu convert JSON --fix 'move_field(title,my_title)' < data.json

In the example above, we renamed all the 'title' fields in the dataset into the 'my\_title' field.

One can also work on deeply nested data. E.g. create a deeply nested data structure with the
'move\_field' command:

    $ catmandu convert JSON --fix 'move_field(title,my.deeply.nested.title)' < data.json

In this example we moved the field 'title' into the field 'my', which contains a (sub)field 'deeply',
which contains a (sub)field 'nested'.

Catmandu was created by librarians for librarians. We process a lot of metadata especially 
library metadata in formats such as MARC, MAB2 and MODS. With the following command we can extract
data from a marc record and to store it into the title field:

    $ catmandu convert MARC --fix 'marc_map(245,title)' < data.mrc

Or, in case only the 245a subfield is needed write:

    $ catmandu convert MARC --fix 'marc_map(245a,title)' < data.mrc

When processing data a lot of Fix commands could be required. It wouldn't be very practical to
type them all on the command line. By creating a Fix script which contains all the fix commands complicated
data transformations can be created. For instance, if the file `myfixes.txt` contains:

     marc_map(245a,title)
     marc_map(100a,author.$append)
     marc_map(700a,author.$append)
     marc_map(020a,isbn)
     replace_all(isbn,'[^0-9-]+','')

then they can be executed on a MARC file using this command:

    $ catmandu convert MARC --fix myfixes.txt < data.mrc

Catmandu contains many powerfull fixes. Visit ["/librecat.org/Catmandu/#fixes-cheat-sheet to get 
an overview what is possible" in http:](https://metacpan.org/pod/http:#librecat.org-Catmandu-fixes-cheat-sheet-to-get-an-overview-what-is-possible)

# Documentation

For more information read our [documentation pages](http://librecat.org/Catmandu/) 
and [blog](https://librecatproject.wordpress.com/)
for a complete introduction and update into all Catmandu features.

In the winter of 2014 a Advent calendar tutorial was created to provide a day by
day introduction into the UNIX command line and Catmandu:

[https://librecatproject.wordpress.com/2014/12/01/day-1-getting-catmandu/](https://librecatproject.wordpress.com/2014/12/01/day-1-getting-catmandu/)

If you need extra training, our developers regulary host workshops at library 
conferences and events: [http://librecat.org/events.html](http://librecat.org/events.html)

# Installation

There are several ways to get a working version of Catmandu on your computer. 
For a quick and demo installation visit our [blog](https://librecatproject.wordpress.com/get-catmandu/)
where a VirtualBox image is available containing all the Catmandu modules, including
ElasticSearch and MongoDB.

On our [website](http://librecat.org/Catmandu/) we provide installation instructions for:

    * Debian
    * Ubuntu Server
    * CentOS
    * openSUSE
    * OpenBSD
    * Windows

and even a generic installation using [Docker](https://www.docker.com/).

# Open Source

Catmandu software published at https://github.com/LibreCat/Catmandu is free software without warranty, liabilities 
or support; you can redistribute it and/or modify it under the terms of the GNU General Public License as 
published by the Free Software Foundation; either version 2 or any later version. Every contributor is free 
to state her/his copyright.

# Developers & Support

Catmandu has a very active international developer community. We welcome all feedback, bug reports and
feature enhancement. 

Join our mailing list to receive more information:  `librecat-dev@librecat.org`

Are a developer and want to contribute to the project? Feel free to submit pull requests or create new
Catmandu packages!

# Kudos

Catmandu is created in a cooperation with many developers world wide. Without them this project isn't possible.
We would like to thank our core maintainer: Nicolas Steenlant and all contributors: Christian Pietsch , 
Dave Sherohman , Friedrich Summann , Jakob Voss , Johann Rolschewski  , Jorgen Eriksson  , Magnus Enger , 
Maria Hedberg , Mathias Loeqsch , Najko Jahn , Nicolas Franck , Patrick Hochstenbach , Petra Kohorst  , 
Snorri Briem , Upasana Shukla and Vitali Peil 

# SEE ALSO

[Catmandu](https://metacpan.org/pod/Catmandu)
