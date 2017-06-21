package Catmandu::Exporter::Mock;

use Catmandu::Sane;

our $VERSION = '1.06';

use Moo;
use namespace::clean;

with 'Catmandu::Exporter';

has _data_ => (is => 'ro', default => sub {[]});

sub add {
    my ($self, $data) = @_;
    push @{$self->_data_}, $data;
    1;
}

sub as_arrayref {
    my ($self) = @_;
    return $self->_data_;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Exporter::Mock - a exporter that doesn't export anything

=head1 SYNOPSIS

    # From the commandline
    $ catmandu convert JSON --fix myfixes to Mock < /tmp/data.json

    # From Perl

    use Catmandu;

    # Print to STDOUT
    my $exporter = Catmandu->exporter('Mock',fix => 'myfix.txt');

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    printf "exported %d objects\n" , $exporter->count;

    # Get an array ref of all records exported
    my $data = $exporter->as_arrayref;

=head1 DESCRIPTION

This exporter exports nothing and can be used as in situations where you e.g. export
data from a fix. Other the Null exporter, the Mock exporter will keep an internal
array of all the records exported which can be retrieved with the 'as_arrayref' method.

=head1 SEE ALSO

L<Catmandu::Exporter::Null>

=cut
