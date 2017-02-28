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

=head1 Select,reject records on some conditions

  # Select all records
  select()

  # Select only records with have 'MARC' in the title
  select all_match(title,'MARC')

  # Select only the records with have a 'foo' field
  select exists(foo)

  # Reject all records
  reject()

  # Reject the records that have a 'foo' field
  reject exists(foo)

=head1 Conditionals

  # uppercase the value of field 'foo' if all members of 'oogly' have the value 'doogly'
  if all_match('oogly.*', 'doogly')
    upcase('foo') # foo => 'BAR'
  else
    downcase('foo') # foo => 'bar'
  end

  # inverted
  unless all_match('oogly.*', 'doogly')
    upcase('foo') # foo => 'BAR'
  end;

  # uppercase the value of field 'foo' if field 'oogly' has the value 'doogly'
  if any_match('oogly', 'doogly')
    upcase('foo') # foo => 'BAR'
  end

  # inverted
  unless any_match('oogly', 'doogly')
    upcase('foo') # foo => 'BAR'
  end

  # uppercase the value of field 'foo' if the field 'oogly' exists
  if exists('oogly')
    upcase('foo') # foo => 'BAR'
  end

  # inverted
  unless exists('oogly')
    upcase('foo') # foo => 'bar'
  end

  # add a new field when the 'year' field is equal to 2018
  if all_equal('year','2018')
    add_field('my.funny.title','true')
  end

  # add a new field when at least one of the 'year'-s is equal to 2018
  if any_equal('years.*','2018')
    add_field('my.funny.title','true')
  end

  # compare things (needs Catmandu 0.92 or better)
  if greater_than('year',2000)
    add_field('recent','yes')
  end

  if less_than('year',1970)
    add_field('ancient','yes')
  end

  # execute fixes if one path is contained in another
  # foo => 1 , bar => [3,2,1]  => in(foo,bar) -> true
  if in(foo,bar)
    add_field(test,ok)
  end

  # only execute fixes if all path values are the boolean true, 1 or "true"
  if is_true(data.*.has_error)
    add_field(error,yes)
  end

  # only execute fixes if all path values are the boolean true, 0 or "false"
  if is_false(data.*.has_error)
    add_field(error,no)
  end

  # only execute the fixes if the path contains an array
  if is_array(data)
    upcase(data.0)
  end

  # only execute the fixes if the path contains an object (an hash, nested field)
  if is_object(data)
    add_field(data.ok,yes)
  end

  # only execute the fixes if the path contains a number
  if is_number(data)
    append(data," : is a number")
  end

  # only execute the fixes if the path contains a string
  if is_string(data)
    append(data," : is a string")
  end

  # only execute the fixes if the path contains 'null' values
  if is_null(data)
    set_field(data,"I'm empty!")
  end

  # Evaludates true when a marc (sub)field matches a regular expression
  if marc_match('245','My funny title')
    add_field('funny.title','yes')
  end
  if marc_match('LDR/6','c')
    marc_set('LDR/6','p')
  end

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
  reverse(author)                            # marc -> cram
  reverse(numbers)                           # [1,2,3] -> [3,2,1]

  trim("field_with_spaces")                  # "  marc  " -> marc

  substring("title",0,1)                     # marc -> m

  prepend("title","die ")                    # marc -> die marc
  append("title"," must die")                # marc -> marc must die

  split_field("foo",":")                     # marc:must:die -> ['marc','must','die']
  join_field("foo",":")                      # ['marc','must','die'] -> marc:must:die

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


  # replace the value with a formatted (sprintf-like) version
  # e.g. numbers:
  #         - 41
  #         - 15
  format(number,"%-10.10d %-5.5d")           # numbers => "0000000041 00015"

  # e.g. hash:
  #        name: Albert
  format(name,"%-10s: %s")                   # hash: "name      : Albert"

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

  # Delete all empty fields from the record
  vacuum()

=head1 Convert from to JSON

    # Convert my.field to a JSON string
    to_json('my.field')

    # Convert the JSON string into my.field into data
    from_json('my.field')

=head1 Lookup values in a file or database

  # Lookup the value in 'title' in dict.csv and replace it with the value found
  lookup("title","dict.csv", sep_char:'|')

  # Lookup the value in 'title' in dict.csv and replace it with the value found
  # Use 'test' as the default value
  lookup("title","dict.csv", default:test)

  # Lookup the value in 'title' in dict.csv and replace it with the value found
  # Delete 'title' when no value has been found
  lookup("title","dict.csv", delete:1)

  # Lookup the value in 'title' a database and replace it with the value found
  lookup_in_store('title', 'MongoDB', database_name:lookups)
  lookup_in_store('title', 'MongoDB', default:'default value' , delete:1)

=head1 Import data from a file or a database

  # Replace the data in foo.bar with an external file or url
  import(foo.bar, JSON, file: "http://foo.com/bar.json", data_path: data.*)

=head1 Store data into a file or a database

  add_to_store('authors.*', 'MongoDB', bag:authors, database_name:catalog)

  # Store the 'data' field in a CSV file
  add_to_exporter(data,CSV,header:1,file:/tmp/data.csv)

  # Store the complete record into a CSV file
  add_to_exporter(.,CSV,header:1,file:/tmp/data.csv)

=head1 Execute all fixes from an external file

  include('/path/to/myfixes.txt')

=head1 Execute external commands

  # Run every record through an external program and collect the results
  # In the example below the Java program MyClass reads JSON records
  # from the STDIN and writes it to the STDOUT
  cmd("java MyClass")

  # Run a Perl script as external fix program. The Perl script must
  # contain an anonymous subroutine which manipulates the record given
  perlcode("myscript.pl")

  # Sleep for one second
  sleep(1,SECOND)

=head1 Write log messages to a Log4perl debugger

  # Send debug messages to a logger
  log('test123')
  log('hello world' , level => 'DEBUG')

=head1 Binds execute complex fixes (loops, error checks, ...)

  # The identity binder doesn't embody any computational strategy. It simply
  # applies the bound fix functions sequentially to its input without any
  # modification.
  do identity()
    add_field(foo,bar)
    add_field(foo2,bar2)
  end

  # Maybe, computes all the fix functions and ignores fixes once they throw errors
  # or return undef.
  do maybe()
    foo()
    return_undef() # rest will be ignored
    bar()
  end

  # List over all items in demo and add a foo => bar field
  # { demo => [{},{},{}] } => { demo => [{foo=>bar},{foo=>bar},{foo=>bar}]}
  do list(path: demo)
    add_field(foo,bar)
  end

  # Print statistical information on the processing speed of fixes to the standaard error.
  do benchmark(output:/dev/stderr)
    foo()
  end

  # Find all ISBN in a stream
  do hashmap(exporter: JSON, join:',')
    # Need an identity binder to group all operations that calculate key_value pairs
    do identity()
     copy_field(isbn,key)
     copy_field(_id,value)
    end
  end

  # Count the number of ISBN occurrences in a stream
  do hashmap(count: 1)
    copy_field(isbn,key)
  end

  # Filter out an array (needs Catmandu 0.9302 or better)
  #    data:
  #       - name: patrick
  #       - name: nicolas
  # to:
  #    data:
  #       - name: patrick
  do with(path:data)
    reject all_match(name,nicolas)
    # Or:
    # if all_match(name,nicolas)
    #  reject()
    # end
  end

  #  run fixes that should run within a time limit
  do timeout(time => 5, units => seconds)
    ...
  end

  # a binder that computes Fix-es for every element in record
  do visitor()
     # upcase all the 'name' fields in the record
     if all_match(key,name)
       upcase(scalar)
     end
  end

  # a binder runs fixes on records from an importer
  do importer(OAI,url: "http://lib.ugent.be/oai")
    retain(_id)
    add_to_exporter(.,YAML)
  end

=head1 MARC manipulation

  # Copy all 245 subfields into the my.title hash
  marc_map('245','my.title')

  # Copy the 245-$a$b$c subfields into the my.title hash in the order of the record
  marc_map('245abc','my.title')

  # Copy the 245-$c$b$a subfields into the my.title hash in the order of the mapping
  marc_map('245cba','my.title' , pluck:1)

  # Copy the 100 subfields into the my.authors array
  marc_map('100','my.authors.$append')

  # Add the 710 subfields into the my.authors array
  marc_map('710','my.authors.$append')

  # Copy the 600-$x subfields into the my.subjects array while packing each into a genre.text hash
  marc_map('600x','my.subjects.$append.genre.text')

  # Copy the 008 characters 35-35 into the my.language hash
  marc_map('008_/35-35','my.language')

  # Copy all the 600 fields into a my.stringy hash joining them by '; '
  marc_map('600','my.stringy', join:'; ')

  # When 024 field exists create the my.has024 hash with value 'found'
  marc_map('024','my.has024', value:found)

  # Do the same examples now with the marc fields in 'record2'
  marc_map('245','my.title', record:record2)

  # Remove the 900 fields
  marc_remove('900')

  # Add a marc field (in Catmandu::MARC 0.110)
  marc_add('999', ind1, ' ' , ind2, '1' , a, 'test123')

  # Add a marc field populated with data from your record
  marc_add('245', a , $.my.title.field, c , $.my.author.field)
  
  # Set a marc value of one (sub)field to a new value
  marc_set('LDR/6','p')
  marc_set('650p','test')
  marc_set('100[3]a','Farquhar family.')

  # Map all 650 subjects into an array
  marc_map('650','subject', join:'###')
  split_field('subject','###')
