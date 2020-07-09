package Catmandu::Exporter::Count;

use Catmandu::Sane;
use Catmandu::Util qw(is_hash_ref is_array_ref is_able);

our $VERSION = '1.2013';

use Moo;
use namespace::clean;

with 'Catmandu::Exporter';

# add is a noop since an Exporter is already a Counter
sub add { }

sub commit {
    my $self = $_[0];
    $self->fh->print($self->count . "\n");
}

# optimize counting
around add_many => sub {
    my ($orig, $self, $many) = @_;

    if (is_hash_ref($many)) {
        $self->inc_count;
        return 1;
    }

    if (is_array_ref($many)) {
        my $n = scalar @$many;
        $self->inc_count($n);
        return $n;
    }

    if (is_able($many, 'count')) {
        my $n = $many->count;
        $self->inc_count($n);
        return $n;
    }

    $orig->($self, $many);
};

1;

__END__

=pod

=head1 NAME

Catmandu::Exporter::Count - a exporter that counts things

=head1 SYNOPSIS

    # From the commandline
    $ catmandu convert JSON to Count < /tmp/data.json


=head1 DESCRIPTION

This exporter exports nothing and just counts the number of items found
in the input data.

=head1 SEE ALSO

L<Catmandu::Cmd::count>

L<Catmandu::Exporter::Null>

=cut
