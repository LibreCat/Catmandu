package Catmandu::Fix::import;

use Catmandu::Sane;

our $VERSION = '1.06';

use Catmandu;
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path       => (fix_arg => 1);
has name       => (fix_arg => 1);
has delete     => (fix_opt => 1);
has ignore_404 => (fix_opt => 1);
has opts       => (fix_opt => 'collect');

sub emit {
    my ($self, $fixer) = @_;
    my $path     = $fixer->split_path($self->path);
    my $key      = pop @$path;
    my $name_var = $fixer->capture($self->name);
    my $opts_var = $fixer->capture($self->opts);
    my $temp_var = $fixer->generate_var;

    $fixer->emit_walk_path(
        $fixer->var,
        $path,
        sub {
            my $var = shift;
            $fixer->emit_get_key(
                $var, $key,
                sub {
                    my $val_var   = shift;
                    my $index_var = shift;
                    my $perl      = $fixer->emit_declare_vars($temp_var);
                    if ($self->ignore_404) {
                        $perl .= "try {";
                    }
                    $perl
                        .= "${temp_var} = Catmandu->importer(${name_var}, variables => ${val_var}, %{${opts_var}})->first;";
                    if ($self->ignore_404) {
                        $perl
                            .= "} catch_case ['Catmandu::HTTPError' => sub {"
                            . "if (\$_->code eq '404') { ${temp_var} = undef; } else { \$_->throw }"
                            . "}];";
                    }
                    $perl .= "if (defined(${temp_var})) {";
                    $perl .= "${val_var} = ${temp_var};";
                    $perl .= "}";
                    if ($self->delete) {
                        $perl .= "else {";
                        if (defined $index_var)
                        { # wildcard: only delete the value where the get failed
                            $perl .= "splice(\@{${var}}, ${index_var}--, 1);";
                        }
                        else {
                            $perl .= $fixer->emit_delete_key($var, $key);
                        }
                        $perl .= "}";
                    }
                    $perl;
                }
            );
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::import - change the value of a HASH key or ARRAY index by replacing
its value with imported data

=head1 SYNOPSIS

   import(foo.bar, JSON, file: "http://foo.com/bar.json", data_path: data.*)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
