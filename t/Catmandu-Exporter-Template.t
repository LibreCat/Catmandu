use Test::More tests => 13; 
use Test::Moose;
use Test::Exception;
use IO::String;
use Catmandu;

BEGIN { use_ok 'Catmandu::Exporter::Template'; }
require_ok 'Catmandu::Exporter::Template';

package T::Each;

our $list = [{'title' => 'cc'}, {'title' => 'dd'}, {'title' => 'ee'}];

sub new { bless {}, shift }

sub each {
    my ($self, $sub) = @_;
    foreach my $obj (@$list) {
        $sub->($obj);
    }
}

package main;

my $xml  = "";
my $file = IO::String->new($xml);

my $template = "<title>[% title %]</title>";
my $exporter = Catmandu::Exporter::Template->new(file => $file, template => \$template);

 isa_ok $exporter, Catmandu::Exporter::Template;
does_ok $exporter, Catmandu::Exporter;

my $n = $exporter->dump({ title => 'abcd'});

is $n , 1;
like $xml , qr/<title>abcd<\/title>/ , "matching otuput";

$file->truncate();

my $n = $exporter->dump([{ title => 'aa'} , { title => 'bb'}]);

is $n , 2;

like $xml , qr/>aa</;
like $xml , qr/>bb</;

$file->truncate();

my $n = $exporter->dump(T::Each->new);

is $n, 3;

like $xml , qr/>cc</;
like $xml , qr/>dd</;
like $xml , qr/>ee</;

done_testing;
