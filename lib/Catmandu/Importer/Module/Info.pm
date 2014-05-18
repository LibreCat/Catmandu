package Catmandu::Importer::Module::Info;
use Catmandu::Sane;
use Moo;
use Module::Info;
use Catmandu::Util qw(:is :check);

our $VERSION = "0.1";

with 'Catmandu::Importer';

has inc => (
    is => 'ro',
    isa => sub { 
      check_array_ref($_[0]); 
    },
    lazy => 1,
    default => sub { [@INC]; }
);
has add_inc => (
    is => 'ro',
    isa => sub { check_array_ref($_[0]); },
    lazy => 1,
    default => sub { []; } 
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

            my @packages;

            require Module::Pluggable;
            my %args = (
                search_path => [$self->namespace],
                search_dirs => [ @{ $self->inc() },@{ $self->add_inc() }],
                sub_name => "_all_ns_packages"
            );
            if(is_natural($self->max_depth)){
                $args{max_depth} = $self->max_depth;
            }
            #use version 4.8 only?
            Module::Pluggable->import(%args);
            push @packages,__PACKAGE__->_all_ns_packages();
                

            for my $package(@packages){

                #reason for this: previous step return first found package, not all installed versions
                push @$modules,Module::Info->all_installed($package,@{ $self->inc });
                
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
 
    Catmandu::Cmd::Module::Info  -  list system available packages in a given namespace 
 
=head1 OPTIONS 
 
    namespace:      namespace for the packages to list 
    inc:            override list of lookup directories (defaults to @INC)
    add_inc:        add list of lookup directories to inc
    max_depth:      maximum depth to search for. Depth means the number of words in the package name
                    e.g.  Catmandu::Fix has a depth of 2
                          Catmandu::Importer::JSON has a depth of 3
 
=head1 SEE ALSO 
 
    L<Catmandu::Importer>

=head1 AUTHOR

    Nicolas Franck, C<< <nicolas.franck at ugent.be> >> 

=cut
1;
