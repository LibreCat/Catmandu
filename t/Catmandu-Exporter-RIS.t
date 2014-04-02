#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Exporter::RIS';
    use_ok $pkg;
}
require_ok $pkg;

my $file = "";
my $exporter = $pkg->new(file => \$file);

my $data = {
	TY => "BOOK",
	TI => "Mastering Perl",
	AU => "brian d foy",
	PY => "2014",
	PB => "O'Reilly",
	XX => "here we go", # unknown key, should be ignored
};

$exporter->add($data);
my $ris = <<EOF;
TY  - BOOK\r
AU  - brian d foy\r
PB  - O'Reilly\r
PY  - 2014\r
TI  - Mastering Perl\r
ER  - \r
EOF

is $ris, $file, "RIS format ok";

done_testing 3;

