package Catmandu::Exporter::JSON;

use 5.010;
use Mouse;
use JSON;

has 'io' => (is => 'ro', required => 1);

sub write {
    my ($self, $obj) = @_;

    my $io    = $self->io;
    my $count = 0;

    given (ref $obj) {
        when ('ARRAY') {
            print $io encode_json($obj);
            $count = scalar @$obj;
        }
        when ('HASH') {
            print $io encode_json($obj);
            $count = 1;
        }
        when (blessed($obj) && $obj->can('each')) {
            print $io '[';
            $obj->each(sub {
                print $io ',' if $count;
                print $io encode_json(shift);
                $count++;
            });
            print $io ']';
        }
        default {
            confess "Can't export";
        }
    }

    $count;
}

sub done {
    1;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 Catmandu::Exporter::JSON - A JSON exporter for
 bibliographic data structures.

=head1 SYNOPSIS

 Catmandu::Exporter::JSON->new(io => $io);

=DESCRIPTION

 See L<Catmandu::Exporter>.

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
