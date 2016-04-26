1;
=head1 NAME

Catmandu::Help::Glossary - A glossary of Catmandu basic concepts

=head1 GLOSSARY

=head2 bind

Part of the L</fix language>.

=head2 catmandu

Name of the data processing framework L<Catmandu> (uppercase) and its command
line client L<catmandu> (lowercase).

=head2 conditional statement

Part of the L</fix language> to control execution of fix functions depending
on whether an item mets some given condition or not. The syntax of conditional
statements is "C<if ... end>", "C<if ... else ... end>", or "C<unless ... end>".

=head2 exporter

Can transform L<item|/items> back into a format such as JSON, YAML, CSV, Excel,
XML ...

=head2 fix

A script written in the L</fix language> or another program that modifies items.

=head2 fix function

A statement of the L<fix language> to modify an item or perform some check on
it.  A L</path language> is used to refer to selected parts of an item.

=head2 fix language

A domain-specific language for manipulation of items. It consists of 
L<fix functions|/fix function>, L<conditional statements/conditional statements>,
and L<binds|/bind>.

=head2 importer

Can transform data from a format such as JSON, YAML, CSV, Excel, XML etc. into an
L</item> for further processing.

=head2 item 

A single data record as processed in Catmandu. Items are data structures build
of key-value pairs ("objects"), lists ("arrays"), strings, numbers, and the
special null-value. All items can be expressed in L<JSON|http://json.org> and
YAML, among other formats.

=head2 iterator

A sequence of L<items|/item>, for instance the list of rows from a CSV file or
the result list or a query.

=head2 validator

A L</fix function> that checks whether an L</item> (or a part of it) conforms
to some given schema or another kind of test.

=cut
