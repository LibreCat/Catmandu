package Catmandu::Importer::Stores;
use Catmandu::Sane;
use Moo;
use Catmandu::Util qw(:check);
use Catmandu::Importer::Module::Info;

with 'Catmandu::Importer';

has local => (
    is => 'ro',
    default => sub { 1; }
);
has inc => (
    is => 'ro',
    isa => sub { check_array_ref($_[0]); },
    default => sub { [@INC]; }
);

sub generator {
    my ($self) = @_;
    sub {
        state $loaded = 0;
        state $modules = [];

        unless($loaded){
            $modules = Catmandu::Importer::Module::Info->new(
                local => $self->local,
                namespace => "Catmandu::Store",
                max_depth => 3,
                inc => $self->inc
            )->to_array();
            $loaded = 1;
        }

        shift @$modules;

    };
}

=head1 NAME

Catmandu::Importer::Stores - list all installed Catmandu stores

=head1 OPTIONS 
 
    local:          list only local packages (default). Only local possible for now.
    inc:            list or lookup directories (defaults to @INC)

=head1 NOTES

    For the moment this importer only list those stores that are directly
    under the namespace Catmandu::Store. If you want to list them all,
    please try L<Catmandu::Importer::Module::Info>.

    Reason: this importer assumes that packages that are directly under the namespace
    of Catmandu::Store are to be considered stores. Other stores that
    have deeper package names are discarded. That would require package inspection
    within a safe environment (see L<Safe>).
=head1 AUTHOR

    Nicolas Franck, C<< <nicolas.franck at ugent.be> >>
    
=cut

1;
