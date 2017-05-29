1;

=pod

=encoding utf8

=head1 Functions

Fix functions manipulate fields in every item of a Catmandu L<Importer|Catmandu::Help::Importers>.
For instance, using the command below the title field will be upcased for every
item in the input list of JSON items.

    $ catmandu convert JSON --fix 'upcase(title)' < data.json

Fix functions can have zero or more B<arguments> separated by commas:

    vacuum()              # Clean all empty fields in a record
    upcase(title)         # Upcase the title value
    append(title,"-123")  # Add -123 at the end of the title value

The arguments to a Fix function can be a B<Fix path> or a B<string literal>.
String literals can be quoted with double or single quotes.

    append(title,"-123")
    append(title,'foo bar')

In case of single quotes all the characters between quotes will be interpreted verbatim.
When using double quotes, the values in quotes can be interpreted by some Fix functions.

    replace_all(title,"My (.*) Pony","Our $1 Fish")   # Replace 'My Little Pony' by 'Our Little Fish'

Some Fix functions accept zero or more B<options> which need to be specified as
a C<name> C<:> C<value> pair:

    sort_field(tags, reverse:1)               # Sort the tags field in reverse order
    lookup("title","dict.csv", sep_char:'|',default:'NONE')  # Lookup a title in a CSV file

Unless specified otherwise (such as in L<Binds|Catmandu::Help::Binds>), Fix function
 are executed in the order given by the Fix script:

    upcase(authors.*)
    append(authors.*,"abc")
    replace_all(authors.*,"a","AB")

In the example above all transformations on the field C<authors> will be executed in
the order given. For example when the field authors contains this list:

    ---
    authors:
      - John
      - Mary
      - Dave

The first fix will transform this list into:

    ---
    authors:
      - JOHN
      - MARY
      - DAVE

The second fix will append "abc" to all authors

    ---
    authors:
      - JOHNabc
      - MARYabc
      - DAVEabc

The third fix will replace all "a"-s by "AB"s

    ---
    authors:
      - JOHNABbc
      - MARYABbc
      - DAVEABbc

In some cases the ordering of transformations of items in a list matters.
For instance, you want to first do a sequence of transformation on all first
items in a list, then a sequence of transformations on all second items in a
list, etc. To change this ordering of Fix functions L<Binds|Catmandu::Help::Binds>
need to be used.

For a nearly complete list of functions currently available in Catmandu, take a
look at the L<Fixes Cheat Sheet|Catmandu::Help::CheatSheet>.
