#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Exporter::Template';
    use_ok $pkg;
}
require_ok $pkg;

my $file = "";
my $template = <<EOF;
Author: [% author %]
Title: "[% title %]"
EOF

my $exporter = $pkg->new(file => \$file, template => \$template);
my $data = {
	author => "brian d foy",
	title => "Mastering Perl",
};

$exporter->add($data);
$exporter->commit;
my $result = <<EOF;
Author: brian d foy
Title: "Mastering Perl"
EOF

is ($file, $result, "Exported Format");

done_testing 3;

