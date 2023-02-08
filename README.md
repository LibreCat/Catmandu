# NAME 

Catmandu::Introduction - A 5 minute introduction to Catmandu

# HELLO WORLD

    $ catmandu convert Null --fix 'add_field(hello,world)'
    [{"hello":"world"}]    

The example above generates the JSON output `[{"hello":"world"}]`
on the standard output. We asked the Catmandu processor to convert
an empty input (`Null`) and add one property `hello` with value
`world`.

We can ask Catmandu not to generate the default JSON output but
convert to a YAML output:

    $ catmandu convert Null --fix 'add_field(hello,world)' to YAML
    ---
    hello: world
    ...  

# FORMAT to FORMAT

Catmandu can be used to convert an input format to an output format.
Use the keyword `to` on the command line:

    $ cat file.yaml
    ---
    hello: world
    ... 
    $ catmandu convert YAML to JSON < file.yaml
    [{"hello":"world"}]  

The left part of the `to` keyword is called the `Importer`, the 
right part of the `to` keyword is called the `Exporter`. Catmandu
provides Importers and Exports for many formats.

# OPTIONS

Each Importer and Exporter can have options that change the behavior
of conversion. The options can be read using the `perldoc` command 
on each Importer and Exports:

    perldoc Catmandu::Importer::YAML
    perldoc Catmandu::Exporter::JSON

Note, many formats are available as Importer and Exporter.

As an example, we can use a JSON Exporter option `pretty` to provide
a pretty printed version of the JSON:

    $ catmandu convert YAML to JSON --pretty 1 < file.yaml
    [{ 
        "hello" : "world"
    }]

# FIX LANGUAGE

Many data conversions need a mapping from one field to another field plus
optional conversions of the data inside these fields. Catmandu provides
the `Fix` language to assist in these mappings. A full list Fix 
functon is available at [https://librecat.org/assets/catmandu\_cheat\_sheet.pdf](https://librecat.org/assets/catmandu_cheat_sheet.pdf).

Fixes can be provided inline as text argument of the command line `--fix` 
argument, or as a pointer to a `Fix Script`. A Fix Scripts groups one or
more fixes in a file.

    $ cat example.fix
    add_field('address.street','Walker Street')
    add_field('address.number','15')
    copy_field('colors.2','best_color')

    $ cat data.yaml
    ---
    colors:
    - Red
    - Green
    - Blue
    ...

    $ catmandu convert YAML --fix example.fix to YAML < data.yaml
    ---
    address:
        number: '15'
        street: Walker Street
    best_color: Blue
    colors:
        - Red
        - Green
        - Blue
    ...

In the example we created the Fix Script `example.fix` that contains
a combination of mappings and data conversion on (nested) data. We 
run a YAML to YAML conversion using the `example.fix` Fix Script.

# SPECIALIZATIONS

Catmandu was mainly created for data conversions of specialized metadata
languages in the field of libraries, archives and museums. One of the
specialized Importers (and Export) is the [Catmandu::MARC](https://metacpan.org/pod/Catmandu%3A%3AMARC) package. This
package can read, write and convert MARC files.

For instance, to extract all the titles from an ISO MARC file one could 
write:

    $ cat titles.fix
    marc_map('245',title)
    retain(title)

    $ catmandu convert MARC --type ISO --fix titles.fix to CSV < data.mrc

The `marc_map` is a specialized Fix function for MARC data. In the example
above the `245` field of each MARC record is mapped to the `title` field.
The `retain` Fix function keeps only the `title` field in the output.

# TUTORIAL

A 18 day tutorial on Catmandu and the Fix language is available at
[https://librecatproject.wordpress.com/tutorial/](https://librecatproject.wordpress.com/tutorial/). 

More information is also available in our wiki [https://github.com/LibreCat/Catmandu/wiki](https://github.com/LibreCat/Catmandu/wiki)
