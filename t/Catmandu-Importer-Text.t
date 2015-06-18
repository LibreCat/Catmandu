use strict;
use warnings;
use Test::More;

use_ok 'Catmandu::Importer::Text';
require_ok 'Catmandu::Importer::Text';

my $text = <<EOF;
Roses are red,
Violets are blue,
Sugar is sweet,
And so are you.
EOF

sub text {
    Catmandu::Importer::Text->new( file => \$text, @_ )->to_array;
}

is_deeply text(), [
       {_id => 1 , text => "Roses are red,"} ,
       {_id => 2 , text => "Violets are blue,"},
       {_id => 3 , text => "Sugar is sweet,"},
       {_id => 4 , text => "And so are you."},
    ], 'simple text import';

is_deeply text( pattern => 'are' ), [
       {_id => 1 , text => "Roses are red,"} ,
       {_id => 2 , text => "Violets are blue,"},
       {_id => 3 , text => "And so are you."},
    ], 'simple pattern match';

is_deeply text( pattern => '(\w+)(.).*\.$' ), [
       {_id => 1 , _1 => "And", _2 => ' '},
    ], 'numbered capturing group';

is_deeply text( pattern => '^(?<first>\w+) (?<second>are).*\,$' ), [
       {_id => 1 , first => "Roses", second => "are"},
       {_id => 2 , first => "Violets", second => "are"},
    ], 'named capturing group';

my $pattern = <<'PAT';
    ^(?<first>   \w+)   # first word
    \                   # space
    (?<second>   are )  # second word = 'are'
PAT

is_deeply text( pattern => $pattern ), [
       {_id => 1 , first => "Roses", second => "are"},
       {_id => 2 , first => "Violets", second => "are"},
    ], 'more legible pattern';

done_testing;
