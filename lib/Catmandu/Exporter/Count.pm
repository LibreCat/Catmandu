package Catmandu::Exporter::Count;

use Catmandu::Sane;

our $VERSION = '1.06';

use Moo;
use namespace::clean;

with 'Catmandu::Exporter';

has _num => (is => 'rw', default => sub {0});

sub add {
    my $self = $_[0];
    $self->_num($self->_num + 1);
}

sub commit {
    my $self = $_[0];
    $self->fh->print($self->_num . "\n");
}

1;

__END__

=pod

=head1 NAME

Catmandu::Exporter::Count - a exporter that counts things

=head1 SYNOPSIS

    # From the commandline
    $ catmandu convert JSON to Count < /tmp/data.json


=head1 DESCRIPTION

This exporter exports nothing and just counts the number of items found
in the input data.

=head1 SEE ALSO

L<Catmandu::Exporter::Null>

=cut
