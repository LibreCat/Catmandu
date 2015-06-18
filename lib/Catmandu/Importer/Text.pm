package Catmandu::Importer::Text;

use namespace::clean;
use Catmandu::Sane;
use Moo;

with 'Catmandu::Importer';

has pattern => (
    is => 'ro',
    coerce => sub {
        my ($p) = @_;  
        return $p if ref $p;
        $p =~ /\n/m ? qr{$p}x : qr{$p}; 
    },
    default => sub { qr/^(?<text>.*$)/ },
);

sub generator {
    my ($self) = @_;
    sub {
        state $pattern = $self->pattern;
        state $cnt = 0;
        state $line;

        while ( defined($line = $self->readline) ) {
            chomp $line;
            next if $line !~ $pattern;

            if (scalar %+) { # named capturing groups
                return { _id => ++$cnt , %+ };
            } else {         # numbered capturing groups
                no strict 'refs';
                my $data = {
                    _id => ++$cnt,
                    map { '_'.$_ => $$_ } grep { defined $$_ } 1..@+-1
                };
                $data->{text} = $line if keys %$data == 1;
                return $data;
            }
        }

        return;
    };
}

1;
__END__

=head1 NAME

Catmandu::Importer::Text - Package that imports textual data

=head1 SYNOPSIS

    use Catmandu::Importer::Text;

    my $importer = Catmandu::Importer::text->new(file => "/foo/bar.yaml");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        
        printf "line %d: text: %s" , $hashref->{_id} , $hashref->{text};  
    });

=head1 DESCRIPTION

This L<Catmandu::Importer> reads each line of input as an item with line number
in field C<_id> and text content in field C<text>. Line separators are not
included. A regular expression can be specified to only import selected lines
and parts of lines that match a given pattern. 

=head1 CONFIGURATION

=over

=item file

Read input from a local file given by its path. Alternatively a scalar
reference can be passed to read from a string.

=item fh

Read input from an L<IO::Handle>. If not specified, L<Catmandu::Util::io> is used to
create the input stream from the C<file> argument or by using STDIN.

=item encoding

Binmode of the input stream C<fh>. Set to C<:utf8> by default.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to imported items.

=item pattern

An regular expression to only import matching lines. If the pattern contains
capturing groups, only these groups are imported as field C<_1>, C<_2>, ...
(numbered capturing groups) or with named capturing groups. If at least one
named capturing group matches, all unnamed capturing groups are ignored.  If
the pattern consists of multiple lines, whitespace is ignored for better
readability. For instance dates in C<YYYY-MM-DD> format can be imported with
one of the following patterns:

   (?<year>\d\d\d\d)-(?<month>\d\d)-(?<day>\d\d)

   (\d\d\d\d)-  # year:  _1
   (\d\d)-      # month: _2
   (\d\d)       # day:   _3

=back

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited. The Catmandu::Importer::YAML methods are not idempotent: YAML feeds
can only be read once.

=head1 SEE ALSO

L<Catmandu::Exporter::Text>

=cut
