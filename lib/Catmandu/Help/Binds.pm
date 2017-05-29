1;

=pod

=encoding utf8

=head1 Binds

B<Binds> change the execution context of a Fix script. In normal operation, all
Fix functions are executed from the first to the last. For example given the YAML
input:

    ---
    colors:
      - red
      - green
      - blue

every Fix functions will be executed one by one on all the colors:

    upcase(colors.*)
    append(colors.*," is a nice color")
    copy_field(colors.*,result.$append)

The first Fix C<upcase> will uppercase all the colors, the second C<append> will
add " is a nice color" to all the colors, the last C<copy_field> will copy all the
colors to a new field.

But what should you do when you want the three Fix functions to operate on each
color separately? First upcase on the first color, append on the first color,
copy_field on the first color, then again upcase on the second color, append on
the second color, etc.

For this type of operation a Bind is needed using the C<do notation>:

    do list(path:colors.*, var:c)
      upcase(c)
      append(c," is a nice color")
      copy_field(c,result.$append)
    end

In the example above the list Bind was introduced. The context of the execution of
the Bind body is changed. Instead of operating on one Catmandu item as a whole,
the Fix functions are executed for each element in the list.

Each Bind changes the execution context in some way. For instance Fix functions
could execute queries into database, or fetch data from the internet. These operations
can fail when the database is down, or the website couldn't be reached. What should
happen in that case in a Fix script? Should the execution be stopped? Or, should
there errors be ignored.

    my_fix1()
    my_fix2()
    download_from_internet() # <--- this one failes
    process_results()

What should happen in the example above? Should the results be processed when the
download_from_internet fails? Using the B<maybe> Bind one can skip Fix functions that fail:

    do maybe()
      my_fix1()
      my_fix2()
      download_from_internet()
      process_results() # <--- this is skipped when download_from_internet fails
    end

Binds are also used when creating Fix executables. That are Fix scripts that can be
run directly from the command line. In the example below we'll write a Fix script
that downloads data from an OAI-PMH repository and prints all the record identifiers:

    #!/usr/bin/env catmandu run
    do importer(OAI,url: "http://lib.ugent.be/oai")
      retain(_id)
      add_to_exporter(.,YAML)
    end

If this script is stored on a file system as myscript.fix and made executable:

    $ chmod 755 myscript.fix

then you can run this script as any other Unix command:

    $ ./myscript.fix
