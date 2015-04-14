package Catmandu::Importer::RIS;

use namespace::clean;
use Catmandu::Sane;
use Moo;

with 'Catmandu::Importer';

has sep_char => (is => 'ro', default => sub {'\s\s-\s'});

sub generator {
    my ($self) = @_;
    sub {
        state $fh = $self->fh;
        state $sep_char = $self->sep_char;
        state $line;
        state $data;
        while($line = <$fh>) {
            chomp($line);
            next if $line eq '';
            if ( $line =~ qr{^([A-Z][A-Z])$sep_char(.*)} ) {
                my ($key, $val) = ($1, $2);
                $val =~ s/\r//;
                $data->{$key} = $val;
            } elsif($line =~ /^ER/) {
                my $tmp = $data;
                $data = {};
                return $tmp;
            }
        }
        return;
    };
}

1;

__END__
=head1 NAME

Catmandu::Importer::RIS - a RIS importer

=head1 SYNOPSIS

Command line interface:

  catmandu convert RIS < input.txt

In Perl code:

  use Catmandu::Importer::RIS;

  my $importer = Catmandu::Importer::RIS->new(file => "/foo/bar.txt");

  my $n = $importer->each(sub {
    my $hashref = $_[0];
    # ...
  });

=head1 CONFIGURATION

=over

=item sep_char

Default is to the regex '\s\s-\s' but sometimes you see RIS like files with
other separator, e.g "TY Foo" instead of "TY  - Foo".

=back

=head1 METHODS

=head2 new(file => $filename, fh => $fh , fix => [...])

Create a new RIS importer for $filename. Use STDIN when no filename is given.

The constructor inherits the fix parameter from L<Catmandu::Fixable>. When given,
then any fix or fix script will be applied to imported items.

=head2 count

=head2 each(&callback)

=head2 ...

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut
