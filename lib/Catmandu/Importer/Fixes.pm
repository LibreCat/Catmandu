package Catmandu::Importer::Fixes;
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
            Catmandu::Importer::ModuleInfo->new(
                max_depth => 4,
                namespace => "Catmandu::Fix",
                inc => [ @{ $self->inc() },@{ $self->add_inc() }]
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
 
    inc:            list or lookup directories (defaults to @INC)
    add_inc:        add list of lookup directories to inc

=head1 NOTES

    This importers assumes that all Catmandu fixes must be within the namespace
    Catmandu::Fix, and must start with a lowercase letter.

    It is not recommended to use this importer from the command line,
    because the command "catmandu convert" only accepts strings for each argument.

    This will work:
        
        catmandu convert fixes

    But this will crash

        catmandu convert fixes --inc . --inc /usr/local/share/perl5

    use this command instead

        catmandu fixes --inc . --inc /usr/local/share/perl5

=head1 AUTHOR

    Nicolas Franck, C<< <nicolas.franck at ugent.be> >>
    
=cut

1;
