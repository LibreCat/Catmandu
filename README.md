# NAME

Catmandu::Introduction - An Introduction to Catmandu data processing toolkit

# STATUS

[![Linux build status](https://github.com/LibreCat/Catmandu/actions/workflows/linux.yml/badge.svg)](https://github.com/LibreCat/Catmandu/actions/workflows/linux.yml) [![Coverage](https://coveralls.io/repos/LibreCat/Catmandu/badge.svg?branch=master)](https://coveralls.io/r/LibreCat/Catmandu) [![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Catmandu.png)](http://cpants.cpanauthors.org/dist/Catmandu)

# Introduction

Catmandu is a data processing toolkit developed as part of the [LibreCat](http://librecat.org) project.  Catmandu provides the command line client [catmandu](https://metacpan.org/pod/catmandu) and a suite of tools to ease the import, storage, retrieval, export and transformation of data. For instance, to transform a CSV file into JSON use the command:

    $ catmandu convert JSON to CSV < data.json

With Catmandu one can import OAI-PMH records in your application (requires [Catmandu::OAI](https://metacpan.org/pod/Catmandu%3A%3AOAI)):

    $ catmandu convert OAI --url http://biblio.ugent.be/oai --set allFtxt

and export records into formats such as JSON, YAML, CSV, XLS, RDF and many more.

Catmandu also provides a data conversion language "Fix" to manipulate data, extract parts of your dataset and transform records. For instance, rename fields  with the [move\_field](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Amove_field) Fix command:

    $ catmandu convert JSON --fix 'move_field(title,my_title)' < data.json

In the example above, we renamed all the `title` fields in the dataset into the `my_title` field.

One can also work on deeply nested data. E.g. create a deeply nested data structure with the `move_field` Fix command:

    $ catmandu convert JSON --fix 'move_field(title,my.deeply.nested.title)' < data.json

In this example we moved the field `title` into the field `my`, which contains a (sub)field `deeply`, which contains a (sub)field `nested`.

Catmandu was originally created by librarians for librarians. We process a lot of metadata especially library metadata in formats such as MARC, MAB2 and MODS. With the following command we can extract data from a marc record and to store it into the title field (requires [Catmandu::MARC](https://metacpan.org/pod/Catmandu%3A%3AMARC)):

    $ catmandu convert MARC --fix 'marc_map(245,title)' < data.mrc

Or, in case only the 245a subfield is needed write:

    $ catmandu convert MARC --fix 'marc_map(245a,title)' < data.mrc

When processing data a lot of Fix commands could be required. It wouldn't be very practical to type them all on the command line. By creating a Fix script which contains all the fix commands complicated data transformations can be created. For instance, if the file `myfixes.txt` contains:

     marc_map(245a,title)
     marc_map(100a,author.$append)
     marc_map(700a,author.$append)
     marc_map(020a,isbn)
     replace_all(isbn,'[^0-9-]+','')

then they can be executed on a MARC file using this command:

    $ catmandu convert MARC --fix myfixes.txt < data.mrc

Fixes can also be turned into executable scripts by adding a bash 'shebang' line at the top. E.g. to harvest records from an OAI repository write this fix file:

     #!/usr/bin/env catmandu run
     do importer(OAI,url:"http://lib.ugent.be/oai")
        add_to_exporter(.,JSON)
     end

Run this (on Linux) by setting the executable bit:

     $ chmod 755 myfix.fix
     $ ./myfix.fix

Catmandu contains many powerful fixes. Visit [http://librecat.org/assets/catmandu\_cheat\_sheet.pdf](http://librecat.org/assets/catmandu_cheat_sheet.pdf) to get an overview what is possible.

# Documentation

For more information read our [documentation pages](https://github.com/LibreCat/Catmandu/wiki) and [blog](https://librecatproject.wordpress.com/) for a complete introduction and update into all Catmandu features.

A tutorial providing a day by day introduction into the UNIX command line and Catmandu is
available at:

[https://librecatproject.wordpress.com/tutorial/](https://librecatproject.wordpress.com/tutorial/)

If you need extra training, our developers regulary host workshops at library conferences such as [SWIB](http://swib.org/) and [ELAG](https://elag.org)

# Installation

There are several ways to get a working version of Catmandu on your computer.

For a quick and demo installation visit our [blog](https://librecatproject.wordpress.com/get-catmandu/) where a VirtualBox image is available containing all the Catmandu modules, including ElasticSearch and MongoDB. A similarly easy method is using [Docker](https://www.docker.com/): At [librecat/catmandu](https://hub.docker.com/r/librecat/catmandu/) a Docker image is provided with version tags for each release, `latest` for the latest release and `dev` for the latest development version. The image can be tried online in a Jupyter notebook [via binder](https://mybinder.org/v2/gh/LibreCat/catmandu-notebook/master).

In our [wiki](https://github.com/LibreCat/Catmandu/wiki/Installation) we provide installation instructions for:

- Debian
- Ubuntu Server
- CentOS
- openSUSE
- OpenBSD
- Windows

# Open Source

Catmandu software published at https://github.com/LibreCat/Catmandu is free software without warranty, liabilities or support; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 or any later version. Every contributor is free to state her/his copyright.

# Developers & Support

We welcome all feedback, bug reports and feature enhancement.

Join our mailing list to receive more information:  `librecat-dev@librecat.org`

Are a developer and want to contribute to the project? Feel free to submit pull requests or create new Catmandu packages!

# Kudos

Catmandu is created in a cooperation with many developers world wide. Without them this project isn't possible.  We would like to thank our core maintainer: Nicolas Steenlant and all contributors: Christian Pietsch, Dave Sherohman, Friedrich Summann, Jakob Voss, Johann Rolschewski, Jorgen Eriksson, Magnus Enger, Maria Hedberg, Mathias Loesch, Najko Jahn, Nicolas Franck, Patrick Hochstenbach, Petra Kohorst, Snorri Briem, Upasana Shukla and Vitali Peil.

# SEE ALSO

[Catmandu](https://metacpan.org/pod/Catmandu)

[http://librecat.org/](http://librecat.org/)
