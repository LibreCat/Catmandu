package Catmandu::Exporter::RIS;

use Catmandu::Sane;
use Moo;
use Encode qw(encode_utf8);

with 'Catmandu::Exporter';

my $TAGS = [qw(TY ID T1 TI CT T2 BT T3 A1 AU A2 ED A3 Y1 PY Y2 N1 AB N2 KW RP
               JF JO JA J1 J2 VL IS CP SP EP CY PB SN AD AV M1 M2 M3 U1 U2 U3 U4 U5
               UR L1 L2 L3 L4)];

my $SMALL_TAG = qr/AU|A2|ED|KW|SP|EP|PB|SN/;

sub add {
    my ($self, $data) = @_;
    my $fh = $self->fh;

    for my $tag (@$TAGS) {
        if (my $vals = $data->{$tag}) {
            $vals = [$vals] unless ref $vals;
            for my $val (@$vals) {
                $val = substr($val, 255) if length($val) > 255 && $val =~ $SMALL_TAG;
                $val = encode_utf8($val);
                print $fh "$tag  - $val\r\n";
            }
        }
    }

    print $fh "ER  - \r\n";
}

1;
