#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON ();

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Exporter::Atom';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [
    { 
        'title'    => 'My Little Pony' ,
        'subtitle' => 'Data testing for you and me' ,
        'content'  => { body => "sdsadas" } ,
        'summary'  => 'Brol 123' ,
        'id'       => '1291821827128172817' ,
        'author' => {
            'name' => 'John Doe' ,
            'email' => 'john@farwaway.org' ,
            'homepage' => 'http://yes.nl',
        } ,
        'contributor' => {
            'name' => 'Rabbit, R' ,
            'email' => 'r.rabbit@farwaway.org' ,
        } ,
        'link' => [
                   {
            'type' => 'text/html' ,
            'rel'  => 'alternate' ,
            'href' => 'http://www.example.com' ,
            'title' => 'Test test' ,
            'length' => '1231' ,
            'hreflang' => 'eng' ,
                    } ,
                   {
            'type' => 'text/html' ,
            'rel'  => 'alternate' ,
            'href' => 'http://www.example2.com' ,
                    }
        ] ,
        'category' => [
                    {
            'scheme' => 'http://localhost:8080/roller/adminblog' ,
            'term' => 'Music',
                    }
        ] ,
        'rights' => 'Yadadada',
        'dc:subject' => 'Toyz',
    }
];
my $file = "";

my $exporter = $pkg->new(file => \$file , 
                         id => "urn:uuid:60a76c80-d399-11d9-b91C-0003939e0af6" ,
                         title => "My Blog" , 
                         subtitle => "testing 1.2.3" ,
                         icon => "http://icons.org/test.jpg" ,
                         logo => "http://icons.org/logo.jpg" ,
                         generator => "Catmandu::Exporter::Atom" ,
                         rights => "Beer license",
                         link => [
                                    {
                             'type' => 'text/html' ,
                             'rel'  => 'alternate' ,
                             'href' => 'http://www.example.com' ,
                                     } 
                         ],
                         author => [ 
                                   {
                             'name' => 'Daffy' ,
                             'email' => 'duck@toons.be' ,
                                   }
                         ] ,
                         contributor => [
                                    {
                              'name'  => 'Bugs' ,
                              'email' => 'bunny@toons.be'
                                    }
                         ],
                         category => [
                                    {
                               'term' => 'animal' ,
                               'scheme' => 'http://example.org/categories/animal' ,
                               'label' => 'Animal'
                                    }
                         ] ,
                         ns => {
                             'dc' => 'http://purl.org/dc/elements/1.1/',
                         },
                         'dc:source' => 'test',  
                    );

isa_ok $exporter, $pkg;

$exporter->add($_) for @$data;
$exporter->commit;

print $file;

done_testing 3;

