package Catmandu::Importer::Multi;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Catmandu::Util qw(is_string);
use Catmandu;
use Catmandu::MultiIterator;
use Moo;
use namespace::clean;

with 'Catmandu::Importer';

has importers => (
    is      => 'ro',
    default => sub {[]},
    coerce  => sub {
        my $importers = $_[0];
        return [
            map {
                if (is_string($_)) {
                    Catmandu->importer($_);
                }
                else {
                    $_;
                }
            } @$importers
        ];
    },
);

sub generator {
    my ($self) = @_;
    sub {
        state $generators = [map {$_->generator} @{$self->importers}];
        while (@$generators) {
            my $data = $generators->[0]->();
            return $data if defined $data;
            shift @$generators;
        }
        return;
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Importer::Multi - Chain multiple importers together

=head1 SYNOPSIS

    use Catmandu::Importer::Multi;

    my $importer = Catmandu::Importer::Multi->new(importers => [
        Catmandu::Importer::Mock->new,
        Catmandu::Importer::Mock->new,
    ]);

    my $importer = Catmandu::Importer::Multi->new(
        'importer1',
        'importer2',
    );

    # return all the items of each importer in turn
    $importer->each(sub {
        # ...
    });

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited.

=cut
