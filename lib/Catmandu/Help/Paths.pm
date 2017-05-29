1;

=pod

=encoding utf8

=head1 Paths

=head2 Paths

Almost any transformation on a Catmandu item contains a path to the part of the
item that needs to be changed. To upcase the C<title> field in an item the Fix
C<upcase> needs to be used:

    upcase(title)

A field can be nested in B<key-value-pairs> (objects). To access the field deep
in a key-value-pair, the B<dot-notation> should be used:

    upcase(my.deep.nested.title)

If a part of an item contains a B<list> of fields than the B<index-notation> should
be used. Use index 0 to point to the first item in a list, index 1 to point to
the second item in a list, index 3 to the third, etc, etc.

    upcase(my.data.2.title)  # upcase the title of the 3rd item in the my.data list

For example, given this YAML input:

    ___
    title: My Little Pony
    my:
     colors:
       - red
       - green
       - blue
     nested:
         a:
          b:
           c: Hoi!

The value 'My Little Pony' can be accessed using the path:

    title

The value 'green' can be accessed using the path:

    my.colors.1

The value 'Hoi!' can be accessed using the path:

    my.nested.a.b.c

=head2 Wildcards

Wildcards are used to point to relative positions or many positions in a list.

To point to the B<first item> in a list (e.g. the value 'red' in the example above)
the wildcard C<$first> can be used:

    my.colors.$first

To point to the B<last item> in a list (e.g. the value 'blue' in the example above)
the wildcard C<$last> can be used:

    my.colors.$last

In some cases, one needs to point to a position before the first item in a list.
For instance, add a new field before the color 'red' in our example above, the wildcard
C<$prepend> should be used:

    my.colors.$prepend

This wildcard can be used in the functions like set_field:

    set_field(my.colors.$prepend,'pink')

To add a new field add the end of a list (after the color 'blue'), the wildcard
C<$append> should be used:

    my.colors.$append

As in:

    set_field(my.colors.$append,'yellow')

The B<star notation> is used to point to all the items in a list:

    my.colors.*

To upcase all the colors use:

    upcase(my.colors.*)

When list are nested inside lists, then wildcards can also be nested:

    my.*.colors.*

The above trick can be used when the my field contains a list which contains a
color field which contains again a list of data. E.g.

    ---
    my:
     - colors:
         - red
         - blue
     - colors:
         - yellow
         - green

=head2 MARC, MAB, PICA paths

For some data formats is can be quite difficult to extract data by the exact
position of a field. In data formats such as MARC, one is unsually not interested
in a field in the 17th position which contains a subfield in position 3. MARC
contains tags and subfields, which can be at any position in the MARC record.

Specialized Fix functions for MARC, MAB and PICA make it easier to access data
by changing the Path syntax. For instance, to copy the 245a field in a MARC
record to the title field one can write:

    marc_map("245a",title)

In the context of a marc_map Fix the "245a" Path is a B<MARC Path> that points to
a part of the MARC record. These MARC Paths only work in MARC Fixes (
C<marc_map>, C<marc_add>, C<marc_set>, C<marc_remove>). It is not possible to
use these paths in other Catmandu fix functions:

    marc_map("245a",title)            # This will work
    copy_field("246a","other_title")  # This will NOT work

Consult the documentation of the different specialised packages for the Path syntax
that can be used.
