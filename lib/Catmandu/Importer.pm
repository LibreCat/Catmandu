use MooseX::Declare;

role Catmandu::Importer {
    use MooseX::Types::IO::All 'IO_All';

    requires 'each';

    has file => (
        is => 'ro',
        isa => IO_All,
        coerce => 1,
        required => 1,
        default => '-',
    );
}

1;

__END__

=head1 NAME

Catmandu::Importer - role describing an importer.

=head1 SYNOPSIS

    $importer->each(sub {
        my $obj = $_[0];
        ...
    });

=head1 METHODS

=head2 $c->file

Returns the io from which objects are imported. Defaults to C<STDIN>.

=head2 $c->each($sub)

Iterates over all objects in C<file> and passes them to C<$sub> as a hashref.
Returns the number of objects imported.

