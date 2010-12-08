use MooseX::Declare;

role Catmandu::Exporter {
    use MooseX::Types::IO::All 'IO_All';

    requires 'dump';

    has file => (
        is => 'ro',
        isa => IO_All,
        coerce => 1,
        required => 1,
        default => '-',
    );

    has pretty => (
        is => 'ro',
        isa => 'Bool',
        default => 0,
    );
}

1;

__END__

=head1 NAME

Catmandu::Exporter - role describing an exporter.

=head1 SYNOPSIS

    $count = $exporter->dump({foo => 'bar});
    $exporter->dump(['foo', 'bar']);
    # export an enumerable object that implements each
    $exporter->dump($obj);

=head1 METHODS

=head2 $c->file

Returns the io to which objects are exported. Defaults to C<STDOUT>.

=head2 $c->pretty([0|1])

Return or set the pretty printing flag. Not all exporters
will respect this flag (eg. binary formats).

=head2 $c->dump($obj)

Exports C<$obj>. C<$obj> can be a hashref, arrayref or an object
responding to C<each>. Returns the number of objects exported.

