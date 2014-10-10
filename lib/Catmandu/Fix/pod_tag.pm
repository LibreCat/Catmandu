package Catmandu::Fix::pod_tag;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;
use Pod::Tree;
use File::Spec;

with 'Catmandu::Fix::Base';

has path => (fix_arg => 1);
has tag => (fix_arg => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;
    my $tag = $self->tag;

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;

            my $file = $fixer->generate_var;
            my $name_parts = $fixer->generate_var;
            my $i = $fixer->generate_var;
            my $pod = $fixer->generate_var;
            my $root = $fixer->generate_var;
            my $child = $fixer->generate_var;
            my $seen_tag = $fixer->generate_var;
            my $tag_content = $fixer->generate_var;
            my $type = $fixer->generate_var;
            my $text = $fixer->generate_var;

            <<EOF
my ${file};

unless ( -f ${var} ) {

    my ${name_parts} = [ split( '::' , ${var} ) ];
    ${name_parts}->[-1] .= ".pm";
    
    for my ${i} ( \@INC ) {

        ${file} = File::Spec->catfile( ${i} , \@{ ${name_parts} } );

        last if -f ${file};

        ${file} = undef;

    }

}
else {

    ${file} = ${var};

}

if ( defined ${file} ){

    my ${pod} = Pod::Tree->new();

    ${pod}->load_file( ${file} );

    if ( ${pod}->loaded() ) {

        my ${root} = ${pod}->get_root();

        if ( defined ${root} ) {

            my ${seen_tag} = 0;
            my ${tag_content};
 
            for my ${child} ( \@{ ${root}->get_children() } ) {

                my ${type} = ${child}->get_type;
                my ${text} = ${child}->get_text;

                if ( ${type} eq "command" && ${text} =~ /$tag/o ) {

                    ${seen_tag} = 1;

                }
                elsif ( ${seen_tag} && ( ${type} eq "verbatim" || ${type} eq "ordinary" ) ) {

                    ${tag_content} = $text;
                    last;
                
                }
                else {

                    ${seen_tag} = 0;

                }

            }

            if ( defined ${tag_content} ) {

                ${var} = $tag_content;

            }


        }
    }

}


EOF
        });
    });
}

=head1 NAME

Catmandu::Fix::pod_tag - show text content for tag in pod

=head1 SYNOPSIS

    #first argument:    module name or path to perl module
    #second argument:   tag name
    pod_tag('file','NAME')

=head1 SYNTAX

pod_tag(<file|package>,<tag>)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
