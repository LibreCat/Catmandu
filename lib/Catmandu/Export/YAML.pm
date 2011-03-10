package Catmandu::Export::YAML;
use IO::YAML;
use Catmandu::Util qw(io is_able);
use Catmandu::Class qw(file);

sub build {
    my ($self, $args) = @_;
    $self->{file} = $args->{file} || *STDOUT;
}

sub default_attribute {
    'file';
}

sub dump {
    my ($self, $obj) = @_;

    my $file = IO::YAML->new(io($self->file, 'w'), auto_load => 1);

    my $n;

    if (ref $obj eq 'HASH') {
        print $file $obj;
        $n = 1;
    } elsif (ref $obj eq 'ARRAY') {
        foreach (@$obj) {
            print $file $_;
        }
        $n = @$obj;
    } elsif (is_able($obj, 'each')) {
        $n = $obj->each(sub { print $file $_[0] });
    } else {
        confess "Invalid object";
    }

    $n;
}

no Catmandu::Util;
1;
