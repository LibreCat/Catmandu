package Catmandu::Fix::retain;

use Catmandu::Sane;

our $VERSION = '1.0601';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has paths => (fix_arg => 'collect', default => sub {[]});

sub emit {
    my ($self, $fixer) = @_;
    my $paths   = $self->paths;
    my $var     = $fixer->var;
    my $tmp_var = $fixer->generate_var;
    my $perl    = $fixer->emit_declare_vars($tmp_var, '{}');
    for (@$paths) {
        my $path = $fixer->split_path($_);
        my $key  = pop @$path;
        $perl .= $fixer->emit_walk_path(
            $var, $path,
            sub {
                my ($var) = @_;
                $fixer->emit_get_key(
                    $var, $key,
                    sub {
                        my ($var) = @_;
                        $fixer->emit_create_path(
                            $tmp_var,
                            [@$path, $key],
                            sub {
                                my ($tmp_var) = @_;
                                "${tmp_var} = ${var};";
                            }
                        );
                    }
                );
            }
        );
    }

    # clear data
    $perl .= $fixer->emit_clear_hash_ref($var);

    # copy tmp data
    $perl .= $fixer->emit_foreach_key(
        $tmp_var,
        sub {
            my ($key) = @_;
            "${var}\->{${key}} = ${tmp_var}\->{${key}};";
        }
    );

    # free tmp data
    $perl .= "undef ${tmp_var};";
    $perl;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::retain - delete everything except the paths given

=head1 SYNOPSIS

   # Keep the field _id , name , title
   retain(_id , name, title)

   # Delete everything except foo.bar 
   #   {bar => { x => 1} , foo => {bar => 1, y => 2}}
   # to
   #   {foo => {bar => 1}}
   retain(foo.bar)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
