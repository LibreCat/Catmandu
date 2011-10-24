package Catmandu::Exporter::RIS;
use Catmandu::Sane;
use Catmandu::Util qw(io quacks);
use Catmandu::Object file => { default => sub { *STDOUT } };
use Encode qw(encode_utf8);

my $tags = [qw(TY ID T1 TI CT T2 BT T3 A1 AU A2 ED A3 Y1 PY Y2 N1 AB N2 KW RP 
               JF JO JA J1 J2 VL IS CP SP EP CY PB SN AD AV M1 M2 M3 U1 U2 U3 U4 U5
               UR L1 L2 L3 L4)];

my $small_tag = qr/AU|A2|ED|KW|SP|EP|PB|SN/;

sub add {
    my ($self, $obj) = @_;

    my $file = io $self->file, 'w';

    my $add = sub {
        my $o = $_[0];

        for my $tag (@$tags) {
            if (my $val = $o->{$tag}) {
                $val = [$val] unless ref $val;
                for my $v (@$val) {
                    $v = substr($v, 255) if length($v) > 255 && $v =~ $small_tag;
                    $v = encode_utf8($v);
                    print $file "$tag  - $v\r\n";
                }
            }
        }

        print $file "ER  - \r\n";
    };

    if (quacks $obj, 'each') {
        return $obj->each($add);
    }

    $add->($obj);
    1;
}

1;
