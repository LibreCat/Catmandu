package Catmandu::Importer::Module::Info;
use Catmandu::Sane;
use Moo;
use Module::Info;
use Catmandu::Util qw(:is :check);

our $VERSION = "0.1";

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
has namespace => (
    is => 'ro',
    required => 1
);
has max_depth => (
    is => 'ro'
);

sub generator {
    my ($self) = @_;
    sub {
        state $loaded = 0;
        state $modules = [];

        unless($loaded){
            my @local_packages;

            if($self->local){
                require Module::Pluggable;
                my %args = (
                    search_path => [$self->namespace],
                    search_dirs => $self->inc(),
                    sub_name => "_all_ns_packages"
                );
                if(is_natural($self->max_depth)){
                    $args{max_depth} = $self->max_depth;
                }
                #use version 4.8 only?
                Module::Pluggable->import(%args);
                push @local_packages,__PACKAGE__->_all_ns_packages();
                
            }

            for my $package(@local_packages){

                #reason for this: previous step return first found package, not all installed versions
                push @$modules,Module::Info->all_installed($package,@INC);
                
            }

            $modules = [map { 
                +{
                    name => $_->name,
                    file => $_->file,
                    version => $_->version
                } 
            } @$modules];

            $loaded = 1;
        }

        shift @$modules;

    };
}

=head1 NAME 
 
    Catmandu::Cmd::Module::Info  -  list available packages in a given namespace 
 
=head1 OPTIONS 
 
    namespace:      namespace for the packages to list 
    local:          list only local packages (default). Only local possible for now.
    inc:            list or lookup directories (defaults to @INC)
 
=head1 SEE ALSO 
 
    L<Catmandu::Importer>

=head1 AUTHOR

    Nicolas Franck, C<< <nicolas.franck at ugent.be> >> 

=cut
1;
