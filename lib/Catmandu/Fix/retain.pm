package Catmandu::Fix::retain;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has paths => (fix_arg => 'collect', default => sub { [] });

sub emit {
    my ($self, $fixer) = @_;
    my $paths = $self->paths;
    my $var = $fixer->var;
    my $tmp_var = $fixer->generate_var;
    my $perl = $fixer->emit_declare_vars($tmp_var, '{}');
    for (@$paths) {
        my $path = $fixer->split_path($_);
        my $key = pop @$path;
        $perl .= $fixer->emit_walk_path($var, $path, sub {
            my ($var) = @_;
            $fixer->emit_get_key($var, $key, sub {
                my ($var) = @_;
                $fixer->emit_create_path($tmp_var, [@$path, $key], sub {
                    my ($tmp_var) = @_;
                    "${tmp_var} = ${var};";
                });
            });
        });
    }
    # clear data
    $perl .= $fixer->emit_clear_hash_ref($var);
    # copy tmp data
    $perl .= $fixer->emit_foreach_key($tmp_var, sub {
        my ($key) = @_;
        "${var}\->{${key}} = ${tmp_var}\->{${key}};";
    });
    # free tmp data
    $perl .= "undef ${tmp_var};";
    $perl;
}

=head1 NAME

Catmandu::Fix::retain - delete everything except the paths given

=head1 SYNOPSIS

   # Delete everything except foo.bar and baz.bar
   retain(foo.bar, baz.bar)

   {bar => 3, foo => {bar => 1, baz => 2}}
   # becomes
   {foo => {bar => 1}}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
