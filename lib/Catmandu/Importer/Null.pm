package Catmandu::Importer::Null;

use Catmandu::Sane;

our $VERSION = '0.9502';

use Moo;
use namespace::clean;

with 'Catmandu::Importer';

sub generator {
    my ($self) = @_;
    my $n = 0;
    sub {
        return undef if $n++;
        +{};
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Importer::Null - Null importer used for testing purposes

=head1 SYNOPSIS

    # On the command line
    catmandu convert Null --fix 'add_field(foo,bar)'   
    # creates { "foo": "bar" }

    # In perl
    use Catmandu::Importer::Null;

    my $importer = Catmandu::Importer::Null->new();

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 DESCRIPTION

The Null importer generated one empty record and exists. This importer can be used to
test fix functions, generating a single record.

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited.

=head1 SEE ALSO

L<Catmandu::Exporter::Null>

=cut
