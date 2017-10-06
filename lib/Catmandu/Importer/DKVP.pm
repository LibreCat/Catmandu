package Catmandu::Importer::DKVP;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Moo;
use namespace::clean;

with 'Catmandu::Importer';

has pair_sep_char => (is => 'ro', default => sub {'='});
has sep_char => (is => 'ro', default => sub {','});
has _re => (is => 'lazy');

sub _build__re {
    my ($self) = @_;
    my $sep_char = $self->sep_char;
    my $pair_sep_char = $self->pair_sep_char;
    qr/([^$pair_sep_char]+)$pair_sep_char([^$sep_char]+)(?:$sep_char|$)/;
}

sub generator {
    my ($self) = @_;

    return sub {
        state $fh = $self->fh;
        state $re = $self->_re;
        if (defined(my $line = <$fh>)) {
            chomp $line;
            my %rec = $line =~ /$re/g;
            return \%rec;
        }
        return;
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Importer::DKVP - Delimited key-value pairs importer

=head1 DESCRIPTION

This package imports text files containing delimited key-value pairs.

    a=pan,b=pan,i=1,x=0.3467901443380824,y=0.7268028627434533
    a=eks,b=pan,i=2,x=0.7586799647899636,y=0.5221511083334797
    a=wye,b=wye,i=3,x=0.20460330576630303,y=0.33831852551664776

=head1 CONFIGURATION

=over

=item sep_char

The character that separates fields. Default is C<,>.

=item pair_sep_char

The character that separates key-value pairs. Default is C<=>.

=back

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable>. All their methods are
inherited.

=head1 SEE ALSO

L<Miller|http://johnkerl.org/miller/doc/file-formats.html#DKVP:_Key-value_pairs>

=cut
