package Catmandu::Exporter;

=head1 NAME

Catmandu::Exporter - Namespace for packages that can export a hashref or iterable object

=head1 SYNOPSIS

    use Catmandu::Exporter::JSON;

    my $exporter = Catmandu::Exporter::JSON->new(file => "/foo/bar.json");

    $exporter->add($object_with_each_method);
    $exporter->add($hashref);

=head1 METHODS

=head2 add

=cut

1;
