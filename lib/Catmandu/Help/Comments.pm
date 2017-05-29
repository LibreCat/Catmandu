1;

=pod

=encoding utf8

=head1 Comments

C<Comments> can be added to the Fix scripts to enhance the readability of your transformations.
All lines that start with a hash sign (#) are ignored by Catmandu:

    # This is a comment
      # This is also a comment
    add_field(foo,bar)  #This is a comment at the and of a line, add_field will be executed
    # remove_field(foo) this line is a comment, remove_field(foo) will not be executed by the script
