package Catmandu::Exporter::JSON;
# ABSTRACT: Streaming JSON exporter
# VERSION
use Moose;
use JSON ();

with qw(
    Catmandu::FileWriter
    Catmandu::Exporter
);

sub dump {
    my ($self, $obj) = @_;

    # we expect that all our data is utf8
    my $json = JSON->new->utf8(0)->pretty($self->pretty);
    my $file = $self->file;

    if (ref $obj eq 'ARRAY') {
        $file->print($json->encode($obj));
        return scalar @$obj;
    }
    if (ref $obj eq 'HASH') {
        $file->print($json->encode($obj));
        return 1;
    }
    if (blessed $obj and $obj->can('each')) {
        my $n = 0;
        my $pretty = $self->pretty;
        $file->print("[");
        $file->print("\n") if $pretty;
        $obj->each(sub {
            my $text = $json->encode($_[0]);
            $pretty and chomp $text;
            $n      and $file->print($pretty ? ",\n" : ",");
            $file->print($text);
            $n++;
        });
        $file->print("\n") if $pretty;
        $file->print("]");
        $file->print("\n") if $pretty;
        return $n;
    }

    confess "Can't export object";
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

