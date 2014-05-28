package Catmandu::Importer::Importers;
use Catmandu::Sane;
use Moo;
use Catmandu::Util qw(:check);
use Catmandu::Importer::ModuleInfo;

with 'Catmandu::Importer';

has inc => (
    is => 'ro',
    isa => sub { check_array_ref($_[0]); },
    default => sub { [@INC]; }
);
has add_inc => (
    is => 'ro',
    isa => sub { check_array_ref($_[0]); },
    lazy => 1,
    default => sub { []; }
);

sub generator {
    my ($self) = @_;
    sub {
        state $loaded = 0;
        state $modules = [];

        unless($loaded){
            $modules = Catmandu::Importer::ModuleInfo->new(
                namespace => "Catmandu::Importer",
                max_depth => 3,
                inc => [ @{ $self->inc() },@{ $self->add_inc() }]
            )->to_array();
            $loaded = 1;
        }

        shift @$modules;

    };
}
=head1 NAME

Catmandu::Importer::Importers - list all installed Catmandu importers

=head1 OPTIONS 
 
    inc:            list or lookup directories (defaults to @INC)
    add_inc:        add list of lookup directories to inc

=head1 NOTES

    For the moment this importer only list those importers that are directly
    under the namespace Catmandu::Importer. If you want to list them all,
    please try L<Catmandu::Importer::ModuleInfo>.

    Reason: this importer assumes that packages that are directly under the namespace
    of Catmandu::Importer are to be considered importers. Other importers that
    have deeper package names are discarded. That would require package inspection
    within a safe environment (see L<Safe>).

    It is not recommended to use this importer from the command line,
    because the command "catmandu convert" only accepts strings for each argument.

    This will work:
        
        catmandu convert importers

    But this will crash

        catmandu convert importers --inc . --inc /usr/local/share/perl5

    use this command instead

        catmandu importers --inc . --inc /usr/local/share/perl5

=head1 AUTHOR

    Nicolas Franck, C<< <nicolas.franck at ugent.be> >>
    
=cut
1;
