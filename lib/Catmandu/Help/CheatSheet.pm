1;

=pod

=encoding utf8

=head1 Fixes Cheat Sheet

This page provides an overview of the Fix language. Fixes clean your data. Every
fix gets as input an item (a Perl HASH) and transforms it with the function and
parameters given.

=head1 Simple fixes to add a field or set its value

  set_field(my.name,patrick)         # { my => { name  => 'patrick'} }
  add_field(my.name2,nicolas)        # { my => { name2 => 'nicolas'} }

  set_array(foo)                     # { foo => [] }
  set_array(foo,a,b,c)               # { foo => ['a','b','c'] }

  set_hash(foo)                      # { foo => {} }
  set_hash(foo,a: b,c: d)            # { foo => { a => 'b', b => 'd' }}

=head1 Copy, move, delete fields

  move_field("my.name","your.name")    # { your => { name => 'patrick'} }
  copy_field("your.name","your.name2") # { your => { name => 'patrick' , name2 => 'patrick'} }
  remove_field("your.name")            # { your => { name => 'patrick'} }

  # Delete every field, except 'id' , 'name' and 'your.name'
  retain("id","name")

=head1 Transform arrays to hashes, hashes to arrays

  # Create an array from a hash
  array("foo")                         # foo => {"name":"value"} => [ "name" , "value" ]

  # Create a hash from an array
  hash("foo")                          # foo => [ "name" , "value" ] => {"name":"value" }

  # Associate two values as a hash key and value
  assoc(fields, pairs.*.key, pairs.*.val) # {pairs => [{key => 'year', val => 2009}, {key => 'subject', val => 'Perl'}]}
                                          # {fields => {subject => 'Perl', year => 2009}, pairs => [...]}

=head1 Manipulate text and numbers

  upcase("title")                            # marc -> MARC
  downcase("title")                          # MARC -> marc
  capitalize("my.deeply.nested.field.0")     # marc -> Marc
  trim("field_with_spaces")                  # "  marc  " -> marc
  substring("title",0,1)                     # marc -> m
  prepend("title","die ")                    # marc -> die marc
  append("title"," must die")                # marc -> marc must die

  split_field("foo",":")                     # marc:must:die -> ['marc','must','die']
  join_field("foo",":")                      # ['marc','must','die'] -> marc:must:die
  retain("id","id2","id3")                   # delete any field except 'id', 'id2', 'id3'
  replace_all("title","a","x")               # marc -> mxrc

  # Most functions can work also work on arrays. E.g.
  replace_all("author.*","a","x")            # [ 'marc','jan'] => ['mxrc','jxn']
  # Use:
  #   authors.$end (last entry)
  #   authors.$start (first entry)
  #   authors.$append (last + 1)
  #   authors.$prepend (first - 1)
  #   authors.* (all authors)
  #   authors.2 (3rd author)

  count("myarray")                           # count number of elements in an array or hash
  sum("numbers")                             # replace an array element with the sum of its values
  sort_field("tags")                         # sort the values of an array
  sort_field("tags", uniq:1)                 # sort the values plus keep unique values
  sort_field("tags", reverse:1)              # revese sort
  sort_field("tags", numeric:1)              # sort numerical values
  uniq(tags)                                 # strip duplicate values from an array
  filter("tags","[Cc]at")                    # filter array values tags = ["Cats","Dogs"] => ["Cats"]
  flatten(deep)                              # {deep => [1, [2, 3], 4, [5, [6, 7]]]} => {deep => [1, 2, 3, 4, 5, 6, 7]}

  # {author => "tom jones"}  -> {author => "senoj mot"}
  reverse(author)

  # {numbers => [1,14,2]} -> {numbers => [2,14,1]}
  reverse(numbers)

  # replace the value with a formatted (sprintf-like) version
  # e.g. numbers:
  #         - 41
  #         - 15
  format(number,"%-10.10d %-5.5d") # numbers => "0000000041 00015"
  # e.g. hash:
  #        name: Albert
  format(name,"%-10s: %s") # hash: "name      : Albert"

  parse_text(date, '(\d\d\d\d)-(\d\d)-(\d\d)')
  # date:
  #    - 2015
  #    - 03
  #    - 07

  #  parses a text into an array or hash of values
  # date: "2015-03-07"
  parse_text(date, '(\d\d\d\d)-(\d\d)-(\d\d)')
  # date:
  #    - 2015
  #    - 03
  #    - 07

  # If you data record is:
  #   a: eeny
  #   b: meeny
  #   c: miny
  #   d: moe
  paste(my.string,a,b,c,d)                 # my.string: eeny meeny miny moe

  # Use a join character
  paste(my.string,a,b,c,d,join_char:", ")  # my.string: eeny, meeny, miny, moe

  # Paste literal strings with a tilde sign
  paste(my.string,~Hi,a,~how are you?)     # my.string: Hi eeny how are you?

  # date: "2015-03-07"
  parse_text(date, '(?<year>\d\d\d\d)-(?<month>\d\d)-(?<day>\d\d)')
  # date:
  #   year: "2015"
  #   month: "03"
  #   day: "07"

  # date: "abcd"
  parse_text(date, '(\d\d\d\d)-(\d\d)-(\d\d)')
  # date: "abcd"

  # '3%A9' => 'café'
  uri_decode(place)
  # 'café' => '3%A9'
  uri_encode(place)

  # Add a new field 'foo' with a random value between 0 and 9
  random(foo, 10)
