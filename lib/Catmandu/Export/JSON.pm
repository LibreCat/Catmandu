package Catmandu::Export::JSON;
use JSON ();
use Catmandu::Util qw(io is_able);
use Catmandu::Class qw(file pretty);

sub build {
    my ($self, $args) = @_;
    $self->{file}   = $args->{file} || *STDOUT;
    $self->{pretty} = $args->{pretty};
}

sub default_attribute {
    'file';
}

sub dump {
    my ($self, $obj) = @_;
    # we assume data is already utf8
    my $json = JSON->new->utf8(0)->pretty($self->pretty);
    my $file = io $self->file, 'w';

    my $n = 0;

    if (ref $obj eq 'HASH') {
        print $file $json->encode($obj);
        $n = 1;
    } elsif (ref $obj eq 'ARRAY') {
        print $file $json->encode($obj);
        $n = @$obj;
    } elsif (is_able($obj, 'each')) {
        my $pretty = $self->pretty;
        print $file "[";
        print $file "\n" if $pretty;
        $obj->each(sub {
            my $j = $json->encode($_[0]);
            chomp $j if $pretty;
            if ($n) {
                print $file ",";
                print $file "\n" if $pretty;
            }
            print $file $j;
            $n++;
        });
        print $file "\n" if $pretty;
        print $file "]";
        print $file "\n" if $pretty;
    } else {
        confess "Invalid object";
    }

    $n;
}

no Catmandu::Util;
1;
