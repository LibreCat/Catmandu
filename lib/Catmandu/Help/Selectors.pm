1;

=pod

=encoding utf8

=head1 Selectors

With B<Fix selectors> one can select which Catmandu items can end up in an output
stream or not. Using a selector to throw away the records you are not interested
in. For instance, to filter out all the records in a input use the B<reject()>
selector:

    $ catmandu MARC to YAML --fix "reject()" < data.mrc

The command above will generate no output: every record is rejected. The opposite
of reject() is the B<select()> selector which can be used to select all the Catmandu
items you want to keep in an output:

    $ catmandu MARC to YAML --fix "select()" < data.mrc

The command above will return all the MARC items in the input file.

Selectors are of little use when used in isolation. Most of the time they are combined
with L<Conditionals|Catmandu::HelpConditionals>. To select only the MARC records
that have "Tsjechov" in the 100a field one can write:

    $ catmandu MARC to YAML --fix "select marc_match(100a,'.*Tsjechov.*') " < data.mrc

There are two alternative ways to combine selector with a conditional.
Using the C<guard> syntax, the conditional is written C<after> the selector:

    reject exits(error.field)
    reject all_match(publisher,'xyz')
    select any_match(years,2005)

Using the C<if>/C<then>/C<else> syntax the conditional is written explicitly:

    if exists(error.field)
       reject()
    end

    if all_match(publisher,'xyz')
       reject()
    end
