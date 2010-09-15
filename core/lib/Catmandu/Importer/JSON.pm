package Catmandu::Importer::JSON;

use Mouse;
use File::Slurp qw(slurp);
use JSON;

has 'io' => (is => 'ro', required => 1);

sub each {
    my ($self, $callback) = @_;

    my $io = $self->io;
    my $array_ref = decode_json(slurp($io));
    if (ref $array_ref ne 'ARRAY') {
        confess "Can only import a JSON array";
    }

    my $count = 0;
    foreach my $obj (@$array_ref) {
        $callback->($obj);
        $count++;
    }
    $count;
}

sub done {
    1;
}

__PACKAGE__->meta->make_immutable;
no Mouse;

__END__

=head1 NAME

 Catmandu::Importer::JSON - An JSON importer for
 bibliographic data structures.

=head1 SYNOPSIS

 Catmandu::Importer::JSON->new(io => $io);

=DESCRIPTION

 See L<Catmandu::Importer>.

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
