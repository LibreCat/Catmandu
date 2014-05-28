package Catmandu::Cmd::stores;
use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Catmandu::Importer::Stores;

sub command_opt_spec {
    (
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

    Catmandu::Importer::Stores->new(

        inc => $opts->inc,
        add_inc => $opts->add_inc

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

Catmandu::Cmd::stores - list local available Catmandu stores

=head1 AUTHOR

    Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=cut
