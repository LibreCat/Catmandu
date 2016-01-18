use strict;
use warnings;
use Test::More;

use_ok 'Catmandu::Importer::Text';
require_ok 'Catmandu::Importer::Text';

my $text = <<EOF;
Roses are red,
Violets are blue,
Sugar is sweet,
And so| are you.
EOF

sub text {
    Catmandu::Importer::Text->new( file => \$text, @_ )->to_array;
}

is_deeply text(), [
       {_id => 1 , text => "Roses are red,"} ,
       {_id => 2 , text => "Violets are blue,"},
       {_id => 3 , text => "Sugar is sweet,"},
       {_id => 4 , text => "And so| are you."},
    ], 'simple text import';

is_deeply text( pattern => 'are' ), [
       {_id => 1 , text => "Roses are red,"} ,
       {_id => 2 , text => "Violets are blue,"},
       {_id => 3 , text => "And so| are you."},
    ], 'simple pattern match';

is_deeply text( pattern => '(\w+)(.).*\.$' ), [
       {_id => 1 , match => ["And"," "]},
    ], 'numbered capturing groups';

my $items = [ {_id => 1 , match => {first => "Roses", second => "are"}},
              {_id => 2 , match => {first => "Violets", second => "are"}} ];

is_deeply text( pattern => '^(?<first>\w+) (?<second>are).*\,$' ), 
    $items, 'named capturing groups';

my $pattern = <<'PAT';
    ^(?<first>   \w+)   # first word
    \                   # space
    (?<second>   are )  # second word = 'are'
PAT

is_deeply text( pattern => $pattern ), 
    $items, 'multiline pattern';

is_deeply [ map { $_->{text} } @{ text( split => ' ' ) } ],
    [ map { [ split ' ', $_ ] } split "\n", $text ],
    'split by character';

is_deeply [ map { $_->{text} } @{ text( split => '|' ) } ],
    [ map { [ split '\\|', $_ ] } split "\n", $text ],
    'split by character (no regexp)';

is_deeply [ map { $_->{text} } @{ text( split => 'is|are' ) } ],
    [ map { [ split /is|are/, $_ ] } split "\n", $text ],
    'split by regexp';

is_deeply text( split => ' is | are ', pattern => '^And so. (.*)' ),
    [ { _id => 1, text => ['And so|','you.'], match => ['are you.'] } ],
    'split and pattern';

done_testing;
