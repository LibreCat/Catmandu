1;

=pod

=encoding utf8

=head1 Conditionals

A B<Conditional> is executed depending on a boolean condition that can be
true or false. For instance, to skip a Catmandu item when the field C<error> exists
one would use the conditional C<exists>:

    if exists(error)
      reject()
    end

A condition contains an C<if> or C<unless> statement a B<Conditional> (Fix functions
which can be true or false), a C<body> of zero or more Fix functions and an
optional C<elsif> or C<else> clause:

    if exists(error)
       # Write here all the Fix functions when the field 'error' exists
    end

    unless exists(error)
      # Write here all the Fix functions when the field 'error' doesn't exist
    end

    if exists(error)
       # If error exists then do this
    elsif exists(warning)
       # If warning exists then do this
    else
       # otherwise do this
    end

Catmandu also supports a limited number of boolean operators:

    exist(foo)  and add_field(ok,1)     # only execute add_field() when 'foo' exists
    exists(foo) or  add_field(error,1)  # only execute add_field() when 'foo' doesn't exist

Below follows some basic fix functions that are implemented in Catmandu. Check
the manual pages of the individual Catmandu extensions for more elaborate Conditionals.

=head2 all_equal(path,value)

True, when the path exists and is exactly equal to a value. When the path points to a
list, then all the list members need to be equal to the value. False otherwise.

    if all_equal(year,"2018")
      set_field(published,"future")
    end

    if all_equal(animals.*,"cat")
      set_field(animal_types,"feline")
    end

=head2 any_equal(path,value)

True, when the path exists and is exactly equal to a value. When the path points to a list,
then at least one of the list members need to be equal to the value. False otherwise.

    if any_equal(year,"2018")
      set_field(published,"future")
    end

    if any_equal(animals.*,"cat")
      set_field(animal_types,"some feline")
    end

=head2 all_match(path,regex)

True, when the path exists and the value matched the regex regular expression. When
the path points to a list, then all the values have to match the regular expression.
False otherwise.

    if all_match(year,"^19.*$")
      set_field(period,"20th century")
    end

    if all_match(publishers.*,"Elsevier.*")
      set_field(is_elsevier,1)
    end

=head2 any_match(path,regex)

True, when the path exists and the value matched the regex regular expression. When
the path points to a list, then at least one of the values has to match the regular
expression. False otherwise.

    if any_match(year,"^19.*$")
      set_field(period,"20th century")
    end

    if any_match(publishers.*,"Elsevier.*")
      set_field(some_elsevier,1)
    end

=head2 exists(path)

True, when the path exists in the Catmandu item. False otherwise.

    if exists(my.deep.field)
    end

    if exists(my.list.0)
    end

=head2 greater_than(path,number)

True, when the path exists and the value is greater than a number. When the path points
to a list, then all the members need to be greater than the number. False otherwise.

=head2 less_than(path,number)

True, when the path exists and the value is less than a number. When the path points
to a list, then all the members need to be less than the number. False otherwise.

=head2 in(path1,path2)

True, when the values of the first path1 are contained in the values at the second path2.
False otherwise.

For instance to check if two paths contain the same values type:

    if in(my.title,your.title)
      set_field(same,1)
    end

To check if a value in one path is contained in a list of an other path type:

    if in(my.author,your.authors.*)
       set_field(known_author,1)
    end

=head2 is_true(path)

True, if the value at path can be evaluated to a boolean true. False otherwise

=head2 is_false(path)

True, if the value at path can be evaluated to a boolean false. False otherwise
