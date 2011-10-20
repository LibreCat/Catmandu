package Catmandu::Exporter::JSON;
use Catmandu::Sane;
use Catmandu::Util qw(io quacks);
use JSON ();
use Catmandu::Object file => { default => sub { *STDOUT } }, pretty => { default => sub { 0 } };

sub add {
    my ($self, $obj) = @_;

    my $json = JSON->new->utf8(0)->pretty($self->pretty ? 1 : 0);
    my $file = io $self->file, 'w';

    if (quacks $obj, 'each') {
        my $p = $self->pretty;
        my $n = 0;
        print $file "[";
        $obj->each(sub {
            my $j = $json->encode($_[0]);
            chomp $j if $p;
            if ($n) {
                print $file ",";
                print $file "\n" if $p;
            }
            print $file $j;
            $n++;
        });
        print $file "]";
        print $file "\n" if $p;

        return $n;
    }

    print $file $json->encode($obj);
    1;
}

1;
