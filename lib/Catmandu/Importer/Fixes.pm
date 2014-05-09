package CatmanduLocalFixes;
use Catmandu::Sane;
use Module::Pluggable search_path => ["Catmandu::Fix"],search_dirs => [@INC];

sub new {
    bless {},$_[0];
}

package Catmandu::Importer::Fixes;
use Catmandu::Sane;
use Moo;
use Module::Info;

with 'Catmandu::Importer';

has local => (
    is => 'ro',
    default => sub { 1; }
);

sub generator {
    my ($self) = @_;
    sub {
        state $loaded = 0;
        state $modules = [];

        unless($loaded){
            my @local_packages;

            if($self->local){
            
                push @local_packages,grep {

                    #filter real fixes
                    my(@parts)= split ':',$_;
                    $parts[-1] =~ /^[a-z][0-9a-z_]+$/o;

                } CatmanduLocalFixes->new()->plugins();
            
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
                };
            } @$modules];

            $loaded = 1;
        }

        shift @$modules;

    };
}

1;
