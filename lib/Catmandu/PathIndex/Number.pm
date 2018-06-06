package Catmandu::PathIndex::Number;

our $VERSION = '1.08';

use Catmandu::Sane;
use Catmandu::Util qw(:is :check);
use Moo;
use Cwd;
use Path::Tiny qw(path);
use Path::Iterator::Rule;
use File::Spec;
use Catmandu::BadArg;
use Catmandu::Error;
use Data::Dumper;
use namespace::clean;

with "Catmandu::PathIndex";

has keysize => (is => 'ro', default => 9, trigger => 1);

sub _trigger_keysize {
    Catmandu::BadArg->throw("keysize needs to be a multiple of 3")
        unless $_[0]->keysize % 3 == 0;
}

sub format_id {
    my ($self, $id) = @_;

    Catmandu::BadArg->throw("need natural number") unless is_natural($id);

    my $n_id = int($id);

    Catmandu::BadArg->throw("id must be bigger or equal to zero")
        if $n_id < 0;

    my $keysize = $self->keysize();

    Catmandu::BadArg->throw(
        "id '$id' does not fit into configured keysize $keysize")
        if length("$id") > $keysize;

    sprintf "%-${keysize}.${keysize}d", $n_id;
}

sub _to_path {
    my ($self, $id) = @_;

    File::Spec->catdir($self->base_dir, unpack("(A3)*", $id));
}

sub _from_path {
    my ($self, $path) = @_;

    my @split_path = File::Spec->splitdir($path);
    my $id         = join("",
        splice(@split_path, scalar(File::Spec->splitdir($self->base_dir))));

    $self->format_id($id);
}

sub get {
    my ($self, $id) = @_;

    my $f_id = $self->format_id($id);
    my $path = $self->_to_path($f_id);

    is_string($path) && -d $path ? {_id => $f_id, _path => $path} : undef;
}

sub add {
    my ($self, $id) = @_;

    my $f_id = $self->format_id($id);
    my $path = $self->_to_path($f_id);

    unless (-d $path) {

        my $err;
        path($path)->mkpath({error => \$err});

        Catmandu::Error->throw(
            "unable to create directory $path: " . Dumper($err))
            if defined($err) && scalar(@$err);

    }

    +{_id => $f_id, _path => $path};
}

sub delete {
    my ($self, $id) = @_;

    my $f_id = $self->format_id($id);
    my $path = $self->_to_path($f_id);

    if (is_string($path) && -d $path) {

        my $err;
        path($path)->remove_tree({error => \$err});

        Catmandu::Error->throw(
            "unable to remove directory $path: " . Dumper($err))
            if defined($err) && scalar(@$err);

    }

    1;
}

sub delete_all {

    my $self = $_[0];

    if (-d $self->base_dir) {

        my $err;
        path($_[0]->base_dir)->remove_tree({keep_root => 1, error => \$err});

        Catmandu::Error->throw("unable to remove entries from base directory "
                . $self->base_dir . ": "
                . Dumper($err))
            if defined($err) && scalar(@$err);

    }

    1;
}

sub generator {
    my $self = $_[0];

    return sub {
        state $rule;
        state $iter;
        state $base_dir = $self->base_dir();

        unless ($iter) {
            $rule = Path::Iterator::Rule->new();
            $rule->min_depth($self->keysize() / 3);
            $rule->max_depth($self->keysize() / 3);
            $rule->directory();
            $iter = $rule->iter($base_dir, {depthfirst => 1});
        }

        my $path = $iter->();

        return unless defined $path;

        my $id = $self->_from_path($path);

        +{_id => $id, _path => $path};
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::PathIndex::Number - A number based path translator

=head1 SYNOPSIS

    use Catmandu::PathIndex::Number;

    my $p = Catmandu::PathIndex::Number->new(
        base_dir => "/data",
        keysize => 9
    );

    # get mapping for id: { _id => 1234, _path => "/data/000/001/234" }
    # can be undef
    my $mapping = $p->get(1234);

    # create mapping for id. Path created if necessary
    my $mapping = $p->add(1234);

    # Catmandu::PathIndex::Number is a Catmandu::Iterable
    # Returns list of records: [{ _id => "000001234", _path => "/data/000/001/234" }]
    my $mappings = $p->to_array();

=head1 METHODS

=head2 new( base_dir => $path , keysize => NUM )

Create a new Catmandu::PathIndex::Number with the following configuration
parameters:

=over

=item base_dir

See L<Catmandu::PathIndex>

=item keysize

By default the directory structure is 3 levels deep. With the keysize option
a deeper nesting can be created. The keysize needs to be a multiple of 3.
All the container keys of a L<Catmandu::Store::File::Simple> must be integers.

=back

=head1 INHERITED METHODS

This Catmandu::PathIndex::Number implements:

=over 3

=item L<Catmandu::PathIndex>

=back

=head1 SEE ALSO

L<Catmandu::PathIndex>

=cut
