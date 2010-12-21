package Catmandu::Exporter::JSON;
# ABSTRACT: Streaming JSON exporter
# VERSION
use namespace::autoclean;
use JSON ();
use Moose;

with qw(Catmandu::Exporter);

sub dump {
    my ($self, $obj) = @_;

    my $json = JSON->new->utf8(1)->pretty($self->pretty);
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
        my $pretty = $self->pretty;
        my $n = 0;
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

1;

