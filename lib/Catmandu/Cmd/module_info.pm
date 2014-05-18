package Catmandu::Cmd::module_info;
use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Catmandu::Importer::Module::Info;

sub command_opt_spec {
    (
        ["namespace|n=s","namespace"],
        ["max_depth=i","maximum depth to search for modules"],
        ["inc|i=s@","override included directories (defaults to \@INC)",{ default => [@INC] }],
        ["add_inc=s@","add lookup directories",{ default => [] }],
        ["verbose|v","include package information"]
    );
}
sub print_simple {
    my $record = $_[0];

    my @p = map { 
        "$_: ".$record->{$_}; 
    } grep { 
        defined($record->{$_}); 
    } qw(name file version);
   
    say join(', ',@p);
}

sub command {
    my ($self, $opts, $args) = @_;

    my $verbose = $opts->verbose;

    Catmandu::Importer::Module::Info->new(

        inc => $opts->inc,
        add_inc => $opts->add_inc,
        namespace => $opts->namespace,
        max_depth => $opts->max_depth

    )->each(sub{
        my $record = $_[0];
        
        unless($verbose){
            say $record->{name}
        }else{      
            print_simple($record);
        }
    });

}

1;

=head1 NAME

Catmandu::Cmd::module_info - list available packages in a given namespace

=head1 OPTIONS

    namespace:      namespace for the packages to list
    local:          list only local packages
    verbose:        add extra information to output (i.e. the file and version)

=head1 SEE ALSO

    L<Catmandu::Importer::Module::Info>
    L<Catmandu::Importer>

=head1 AUTHOR

    Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=cut
