package Catmandu::Fix::collapse;

use Catmandu::Sane;

our $VERSION = '1.06';

use Moo;
use Catmandu::Expander ();
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

has sep => (fix_opt => 1, default => sub {undef});

sub fix {
    my ($self, $data) = @_;
    my $ref = Catmandu::Expander->collapse_hash($data);

    if (defined(my $char = $self->sep)) {
        my $new_ref = {};
        for my $key (keys %$ref) {
            my $val = $ref->{$key};
            $key =~ s{\.}{$char}g;
            $new_ref->{$key} = $val;
        }
        $ref = $new_ref;
    }

    $ref;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::collapse - convert nested data into a flat hash using the TT2 dot convention

=head1 SYNOPSIS

   # Collapse the data into a flat hash
   collapse()

   # Collaps the data into a flat hash with '-' as path seperator
   collapse(-sep => '-')

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
