package Catmandu::Importer::Fixes;
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
            Catmandu::Importer::Module::Info->new(
                local => $self->local,
                max_depth => 4,
                namespace => "Catmandu::Fix",
                inc => $self->inc
            )->each(sub{
                my $record = $_[0];
                #filter real fixes
                my(@parts)= split ':',$record->{name};
                push @$modules,$record if $parts[-1] =~ /^[a-z][0-9a-z_]+$/o;
            });
            $loaded = 1;
        }

        shift @$modules;

    };
}

=head1 NAME

Catmandu::Importer::Fixes - list all installed Catmandu fixes

=head1 OPTIONS 
 
    local:          list only local packages (default). Only local possible for now.
    inc:            list or lookup directories (defaults to @INC)

=head1 NOTES

    This importers assumes that all Catmandu fixes must be within the namespace
    Catmandu::Fix, and must start with a lowercase letter.

=head1 AUTHOR

    Nicolas Franck, C<< <nicolas.franck at ugent.be> >>
    
=cut

1;
