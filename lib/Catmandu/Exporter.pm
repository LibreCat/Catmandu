package Catmandu::Exporter;

use Catmandu::Sane;
use Catmandu::Util qw(io);
use Moo::Role;

with 'Catmandu::Addable';
with 'Catmandu::Counter';

has file => (
    is      => 'ro',
    lazy    => 1,
    default => sub { \*STDOUT },
);

has fh => (
    is      => 'ro',
    lazy    => 1,
    default => sub { io($_[0]->file, mode => 'w', encoding => $_[0]->encoding) },
);

after add => sub {
    $_[0]->inc_count;
};

sub encoding { ':utf8' }

sub commit { 1 }

=head1 NAME

Catmandu::Exporter - Namespace for packages that can export a hashref or iterable object

=head1 SYNOPSIS

    use Catmandu::Exporter::JSON;

    my $exporter = Catmandu::Exporter::JSON->new(file => "/foo/bar.json");

    $exporter->add($object_with_each_method);
    $exporter->add($hashref);

=head1 METHODS

=head2 new

=head2 add

=cut

1;
