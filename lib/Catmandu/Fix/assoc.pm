package Catmandu::Fix::assoc;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

has path      => (fix_arg => 1);
has keys_path => (fix_arg => 1);
has vals_path => (fix_arg => 1);

with 'Catmandu::Fix::Base';

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $keys_path = $fixer->split_path($self->keys_path);
    my $vals_path = $fixer->split_path($self->vals_path);
    my $keys_key = pop @$keys_path;
    my $vals_key = pop @$vals_path;
 
    my $keys_var = $fixer->generate_var;
    my $vals_var = $fixer->generate_var;
    my $perl = $fixer->emit_declare_vars([$keys_var, $vals_var], ['[]', '[]']);

    $perl .= $fixer->emit_walk_path($fixer->var, $keys_path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $keys_key, sub {
            my $var = shift;
            "push(\@{${keys_var}}, ${var}) if is_value(${var});";
        });
    });
    $perl .= "if (\@{${keys_var}}) {" .
        $fixer->emit_walk_path($fixer->var, $vals_path, sub {
            my $var = shift;
            $fixer->emit_get_key($var, $vals_key, sub {
                my $var = shift;
                "push(\@{${vals_var}}, ${var});";
            });
        }) .
        $fixer->emit_create_path($fixer->var, $path, sub {
            my $var = shift;
            "if (is_hash_ref(${var} //= {})) {" .
                "while (\@{${keys_var}} && \@{${vals_var}}) {" .
                    "${var}\->{shift(\@{${keys_var}})} = shift(\@{${vals_var}});" .
                "}" .
            "}";
        }) .
    "}";

    $perl;
}

=head1 NAME

Catmandu::Fix::assoc - associate two values as a hash key and value

=head1 SYNOPSIS

   # {pairs => [{key => 'year', val => 2009}, {key => 'subject', val => 'Perl'}]}
   assoc(fields, pairs.*.key, pairs.*.val)
   # {fields => {subject => 'Perl', year => 2009}, pairs => [...]}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
