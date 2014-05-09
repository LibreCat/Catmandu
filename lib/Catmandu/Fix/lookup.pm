package Catmandu::Fix::lookup;

use Catmandu::Sane;
use Catmandu::Importer::CSV;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path       => (fix_arg => 1);
has file       => (fix_arg => 1);
has default    => (fix_opt => 1);
has delete     => (fix_opt => 1);
has csv_args   => (fix_opt => 'collect');
has dictionary => (is => 'lazy', init_arg => undef);

sub _build_dictionary {
    my ($self) = @_;
    Catmandu::Importer::CSV->new(
        %{$self->csv_args},
        file   => $self->file,
        header => 0,
        fields => ['key', 'val'],
    )->reduce({}, sub {
        my ($dict, $pair) = @_;
        $dict->{$pair->{key}} = $pair->{val};
        $dict;
    });
}

sub emit {
    my ($self, $fixer) = @_;
    my $path     = $fixer->split_path($self->path);
    my $key      = pop @$path;
    my $dict_var = $fixer->capture($self->dictionary);
    my $delete   = $self->delete;
    my $default  = $self->default;

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $val_var = shift;
            my $val_index = shift;
            my $dict_val_var = $fixer->generate_var;
            my $perl = "if (is_value(${val_var}) && defined(my ${dict_val_var} = ${dict_var}->{${val_var}})) {" .
                "${val_var} = ${dict_val_var};" .
            "}";
            if ($delete) {
                $perl .= "else {";
                if (defined $val_index) { # wildcard: only delete the value where the lookup failed
                    $perl .= "splice(\@{${var}}, ${val_index}--, 1);";
                } else {
                    $perl .= $fixer->emit_delete_key($var, $key);
                }
                $perl .= "}";
            } elsif (defined $default) {
                $perl .= "else {" .
                    $fixer->emit_set_key($var, $key, $fixer->emit_value($default)) .
                "}";
            }
            $perl;
        });
    });
}

=head1 NAME

Catmandu::Fix::lookup - change the value of a HASH key or ARRAY index by looking up it's value in a dictionary

=head1 SYNOPSIS

   lookup('foo.bar', 'dictionary.csv');
   lookup('foo.bar', 'dictionary.csv', sep_char: '|');
   # delete value if the lookup fails:
   lookup('foo.bar', 'dictionary.csv', delete: 1);
   # use a default value if the lookup fails:
   lookup('foo.bar', 'dictionary.csv', default: 'default value');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
