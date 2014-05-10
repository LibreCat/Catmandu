package Catmandu::Cmd::doc;
use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Pod::Perldoc;

sub command_opt_spec {
    ();
}

sub command {
    my ($self, $opts, $args) = @_;

    Pod::Perldoc->new(args => [$args->[0]])->process;        

}

1;

=head1 NAME

Catmandu::Cmd::doc - show documentation for a Catmandu module

=cut
