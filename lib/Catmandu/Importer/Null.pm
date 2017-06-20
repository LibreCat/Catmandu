package Catmandu::Importer::Null;

use Catmandu::Sane;

our $VERSION = '1.06';

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

    # From the command line

    catmandu convert Null --fix 'add_field(foo,bar)'   
    # creates { "foo": "bar" }

    # In a Perl script
    use Catmandu;

    my $importer = Catmandu->importer('Null');

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 DESCRIPTION

The importer generates one empty record and then exists. This importer can be used to
test fix functions, generating a single record.

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited.

=head1 SEE ALSO

L<Catmandu::Exporter::Null>

=cut
