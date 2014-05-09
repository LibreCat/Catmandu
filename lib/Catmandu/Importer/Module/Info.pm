package Catmandu::Importer::Module::Info;
use Catmandu::Sane;
use Moo;
use Module::Info;

with 'Catmandu::Importer';

has local => (
    is => 'ro',
    default => sub { 1; }
);
has namespace => (
    is => 'ro',
    required => 1
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
                Module::Pluggable->import(
                    search_path => [$self->namespace],
                    search_dirs => [@INC],
                    sub_name => "_all_ns_packages"
                );
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

1;
