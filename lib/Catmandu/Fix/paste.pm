package Catmandu::Fix::paste;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path   => (fix_arg => 1);
has values => (fix_arg => 'collect');

sub emit {
    my ($self, $fixer) = @_;
    my $values = $self->values;

    my @parsed_values = ();
    my $join_char     = ' ';

    while (@$values) {
        my $val = shift @$values;
        if ($val eq 'join_char') {
            $join_char = shift @$values;
            last;
        }
        else {
            push @parsed_values, $val;
        }
    }

    $join_char = $fixer->emit_string($join_char);

    my $vals_var = $fixer->generate_var;
    my $perl = $fixer->emit_declare_vars($vals_var, '[]');

    for my $val (@parsed_values) {
        my $vals_path = $fixer->split_path($val);
        my $vals_key  = pop @$vals_path;

        if ($val =~ /^~(.*)/) {
            my $tmp = $fixer->emit_string($1);
            $perl .= "push(\@{${vals_var}}, ${tmp});";
        }
        else {
            $perl .= $fixer->emit_walk_path(
                $fixer->var,
                $vals_path,
                sub {
                    my $var = shift;
                    $fixer->emit_get_key(
                        $var,
                        $vals_key,
                        sub {
                            my $var = shift;
                            "push(\@{${vals_var}}, ${var}) if is_value(${var});";
                        }
                    );
                }
            );
        }
    }

    my $path = $fixer->split_path($self->path);

    $perl .= $fixer->emit_create_path(
        $fixer->var,
        $path,
        sub {
            my $var = shift;
            "${var} = join(${join_char}, \@{${vals_var}});";
        }
    );

    $perl;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::paste - concatenate path values

=head1 SYNOPSIS

   # If you data record is:
   #   a: eeny
   #   b: meeny
   #   c: miny
   #   d: moe
   paste(my.string,a,b,c,d)                 # my.string: eeny meeny miny moe

   # Use a join character
   paste(my.string,a,b,c,d,join_char:", ")  # my.string: eeny, meeny, miny, moe

   # Paste literal strings with a tilde sign
   paste(my.string,~Hi,a,~how are you?)    # my.string: Hi eeny how are you?

=head1 DESCRIPTION

Paste places a concatenation of all paths starting from the second path into the first path.
Literal values can be pasted by prefixing them with a tilde (~) sign.

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
