use Test::Exception;
use Test::Moose;
use Test::More;

BEGIN {
    plan( tests => 15 );
}

BEGIN { use_ok 'Catmandu::Importer::Aleph'; }
require_ok 'Catmandu::Importer::Aleph';

my $marc  = join("",<DATA>);
my $importer = Catmandu::Importer::Aleph->new(file => \$marc, inline_map => [
       '001'   => '_id' ,
       '260+a' => 'publisher',
       '024-a' => 'info',
       '9**+a' => 'type',
]);

isa_ok  $importer, Catmandu::Importer::Aleph;
does_ok $importer, Catmandu::Importer;

my $n = $importer->each( sub {
    my $obj = shift;

    ok($obj->{_id} , 'has _id');

    like $obj->{_id}->[0] , qr/000222594|000728042/ , 'got correct _id';

    like $obj->{publisher}->[0] , qr/Paris :|Antwerpen :/ , 'got correct include subfield publisher';

    like $obj->{info}->[0] , qr/info/ , 'got correct exclude subfield info';

    like $obj->{type}->[0] , qr/map|book/ , 'got correct selector match';
});

is $n , 2;

done_testing;

__DATA__
000222594 FMT   L BK
000222594 LDR   L 00000nam^a22^^^^^^a^4500
000222594 001   L 000222594
000222594 005   L 20050826205650.0
000222594 008   L 901218s1691^^^^xx^^^^^^^^^^^^^^^^^^^^^^^
000222594 0247  L $$aBRKZ-MGB-440-005_2009_0001_AC$$2info
000222594 040   L $$aUGent
000222594 24500 L $$aHistoire du roy Louis le Grand par les médailles, emblêmes, deuises, jettons, inscriptions, armoiries, et autres monumens publics /$$cReceuillis, et expliquéz par Claude-François Ménestrier.
000222594 260   L $$aParis :$$bNolin,$$c1691.
000222594 300   L $$a54 p.: ill.
000222594 7001  L $$aMenestrier, Claude François
000222594 8524  L $$bCA20$$cBHSL$$jBHSL.MGB.440/005$$LBIB.HIST.004464
000222594 920   L $$abook
000728042 FMT   L MP
000728042 LDR   L 00000nem^a22^^^^^^a^4500
000728042 001   L 000728042
000728042 005   L 20050826224016.0
000728042 008   L 020610s1749^^^^xx^^^^^^^^a^^^^^0^^^dut^d
000728042 0247  L $$aBRKZ-KRT-1591_2009_0001_AC$$2info
000728042 0247  L $$aBRKZ-KRT-1591_2009_0002_AC$$2info
000728042 040   L $$aUGent
000728042 1001  L $$aStijnen, P.
000728042 24510 L $$aCaerte figurative vande situatie der stadt Antwerpen met de forten, polders, bedijckte landen, schorren, ende slijcken da er annex gelegen aende Oost ende West sijde vande riviere de Schelde gemaeckt ende getrocken uyt de respective originele polder caerten, ende vorts door eygene metingen ende oculeire inspectie der plaetsen gedaen door den onderschreven gesworen landt meter :$$bactum Antwerpiae 23 aug ustü 1748 /$$cP. Stijnen$$h[cartographic material]
000728042 255   L $$aSchaal in Antwerpse roeden
000728042 260   L $$aAntwerpen :$$bs.n.,$$c1749.
000728042 300   L $$a1 krt. :$$bkopergravure (P. B. Bouttats) gekleurd ;$$c143 x 103,5 cm.
000728042 500   L $$aGeen legende
000728042 500   L $$aWindroos
000728042 500   L $$aCartouche met 3 engelen en 2 horens en mand des overvloeds
000728042 500   L $$aOp de achterkant sporen van zegellak
000728042 690   L $$aKaart Antwerpen, polders
000728042 8524  L $$bCA20$$cBRKZ$$jBRKZ.KRT.1591
000728042 920   L $$amap
