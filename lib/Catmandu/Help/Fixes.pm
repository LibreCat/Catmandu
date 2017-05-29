1;

=pod

=encoding utf8

=head1 Fixes

Fixes are used for easy data transformations by non programmers. Using a small
L<Fix language|Catmandu::Help::FixLanguage> non-programmers can manipulate
Catmandu L<Items|Catmandu::Help::Items>.

To introduce the capabilities of Fix, an example will be provided below to extract
data from a MARC input.

First, make sure that Catmandu::MARC is installed on your system.

 $ sudo cpanm Catmandu::MARC

We will use the Catmandu command line client to extract data from an example USMARC
file that can be downloaded via this link: L<https://github.com/LibreCat/Catmandu/wiki/files/camel.usmarc>.

With the convert command one can read items from a MARC Importer and convert it into a
new format. By default, convert will output JSON:

    $ catmandu convert MARC < camel.usmarc
    {"record":[["LDR",null,null,"_","00755cam  22002414a 4500"],["001",null,null...
    ...
    ["650"," ","0","a","Cross-platform software development."]],"_id":"fol05882032 "}

You can make this conversion explicit:

    $ catmandu convert MARC to JSON < camel.usmarc

To transform this MARC data we first will create a Fix file which contains all the Fix
commands we will use. Create a text file 'fixes.txt' on your system with this input:

    remove_field('record');

and execute the following command:

    $ catmandu convert MARC --fix fixes.txt < camel.usmarc
    {"_id":"fol05731351 "}
    {"_id":"fol05754809 "}
    {"_id":"fol05843555 "}
    {"_id":"fol05843579 "}

We have removed the field 'record' (containing the MARC data) from the JSON record.
This is what the 'remove_field' Fix does: remove one field in a JSON record. We will use
this remove_field('record') to make our output a bit more terse and easier readable.

With the 'marc_map' Fix from the Catmandu::MARC package we can extract MARC (sub)fields
from the record. Add these to the fixes.txt file:

    marc_map('245','title');
    remove_field('record');

When we run our previous catmandu command we get the following output:

    $ catmandu convert MARC --fix fixes.txt to JSON --line_delimited 1 < camel.usmarc
    {"_id":"fol05731351 ","title":"ActivePerl with ASP and ADO /Tobias Martinsson."}
    {"_id":"fol05754809 ","title":"Programming the Perl DBI /Alligator Descartes and Tim Bunce."}
    {"_id":"fol05843555 ","title":"Perl :programmer's reference /Martin C. Brown."}

We know that in the 650-a field of MARC we can find subjects. Lets add them to the fixes.txt:

    marc_map('245','title');
    marc_map('650a','subject');
    remove_field('record');

and run the command again:

    $ catmandu convert MARC --fix fixes.txt to JSON --line_delimited 1 < camel.usmarc
    {"subject":"Perl (Computer program language)","_id":"fol05731351 ","title":"ActivePerl with ASP and ADO /Tobias Martinsson."}
    {"subject":"Perl (Computer program language)Database management.","_id":"fol05754809 ","title":"Programming the Perl DBI /Alligator Descartes and Tim Bunce."}
    {"subject":"Perl (Computer program language)","_id":"fol05843555 ","title":"Perl :programmer's reference /Martin C. Brown."}

The MARC 008 field from position 7 to 10 contains publication years. We can also add these to the 'fixes.txt' file:

    marc_map('245','title');
    marc_map('650a','subject');
    marc_map('008/7-10,'year');
    remove_field('record');

and run the command:

    $ catmandu convert MARC --fix fixes.txt to JSON --line_delimited 1 < camel.usmarc
    {"subject":"Perl (Computer program language)","_id":"fol05731351 ","title":"ActivePerl with ASP and ADO /Tobias Martinsson.","year":"2000"}
    {"subject":"Perl (Computer program language)Database management.","_id":"fol05754809 ","title":"Programming the Perl DBI /Alligator Descartes and Tim Bunce.","year":"2000"}
    {"subject":"Perl (Computer program language)","_id":"fol05843555 ","title":"Perl :programmer's reference /Martin C. Brown.","year":"1999"}

You don't need to write fixes into a file to use them. E.g. if we want to have some statistic on the publication year in the camel.usmarc file we can do something like:

    $ catmandu convert MARC --fix "marc_map('008/7-10','year'); retain_field('year')" to CSV < camel.usmarc
    year
    2000
    2000
    1999
    .
    .

With marc_map we extracted the year form the 008 field. With retain_field we deleted everything
in the output except for the field 'year'. We used the CSV Exporter to present the results in an
easy format.
