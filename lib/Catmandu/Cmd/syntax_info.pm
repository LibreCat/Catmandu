package Catmandu::Cmd::syntax_info;

use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Pod::Tree;
use Catmandu::Fix::pod_tag;

sub command_opt_spec {
    (
        ["input|i=s", "Package name or file path",{ required => "true" }],
        
    );
}

sub command {

    my ($self, $opts, $args) = @_;

    my $syntax = Catmandu::Fix::pod_tag->new( 'syntax','SYNTAX' )->fix( { syntax => $opts->input } )->{syntax};

    if($syntax eq $opts->input){
        
        say STDERR "no syntax information found in pod";
        exit 1;

    }

    $syntax =~ s/^\s+//go;
    $syntax =~ s/\s+$//go;

    say $syntax;

}

1;

=head1 NAME

Catmandu::Cmd::syntax_info - show syntax info for catmandu module

=head1 SEE ALSO

    L<Catmandu::Fix>
    L<Catmandu::Fix::SyntaxInfo>

=cut
