package Catmandu::Fix::paste;

use Catmandu::Sane;

our $VERSION = '1.2025';

use Moo;
use Catmandu::Util       qw(is_value is_code_ref);
use Catmandu::Util::Path qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path => (fix_arg => 1);
has args => (fix_arg => 'collect');

sub _build_fixer {
    my ($self)    = @_;
    my $args      = $self->args;
    my $join_char = ' ';
    my $getters   = [];
    my $creator   = as_path($self->path)->creator;

    for (my $i = 0; $i < @$args; $i++) {
        my $arg = $args->[$i];
        if ($arg eq 'join_char') {
            $join_char = $args->[$i + 1];
            last;
        }
        elsif (my ($literal) = $arg =~ /^~(.*)/) {
            push @$getters, $literal;
        }
        else {
            push @$getters, as_path($arg)->getter;
        }
    }

    sub {
        my $data = $_[0];
        my $vals = [];
        for my $getter (@$getters) {
            if (is_code_ref($getter)) {
                push @$vals, grep {is_value($_)} @{$getter->($data)};
            }
            else {
                push @$vals, $getter;
            }
        }
        $creator->($data, join($join_char, @$vals));
        $data;
    };
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
   paste(my.string,~Hi,a,~how are you?)     # my.string: Hi eeny how are you?

   # Paste works even when not all values are instantiated
   paste(my.string,x,a,z)                   # my.string: eeny

=head1 DESCRIPTION

Paste places a concatenation of all paths starting from the second path into the first path.
Literal values can be pasted by prefixing them with a tilde (~) sign. 

When a path doesn't exist it is regarded as having an empty '' value.

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
