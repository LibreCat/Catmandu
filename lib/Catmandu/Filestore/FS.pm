package Catmandu::Filestore::FS;
use Catmandu::Sane;
use Catmandu::Util qw(is_able io get_or_set_id check_id opts);
use File::Path ();
use File::Copy qw(copy);
use File::Spec;
use File::Slurp qw(write_file read_file);
use JSON;
use Catmandu::Object path => 'r';

sub _build_args {
    my ($self, $path, @args) = @_;
    my $args = opts(@args);
    $args->{path} = $path;
    $args;
}

sub _build {
    my ($self, $args) = @_;
    $self->{path} = $args->{path};
    $self->_create_path($self->path);
}

sub get {
    my ($self, $id) = @_;
    my $path = $self->path_to($id);
    my $json = File::Spec->catfile($path, "$id.json");
    -f $json || return;
    decode_json(read_file($json));
}

sub each {
    my ($self, $sub) = @_;
    confess "TODO";
}

sub _add {
    my ($self, $obj) = @_;
    my $id   = get_or_set_id($obj);
    my $from = $obj->{_file} || confess("missing _file");
    my $path = $self->path_to($id);
    my $into = $obj->{_file} = File::Spec->catfile($path, $id);
    $self->_create_path($path);
    write_file("$into.json", to_json($obj, {utf8 => 1, pretty => 1}));
    copy($from, $into);
    $obj;
}

sub add {
    my ($self, $obj) = @_;
    if (is_able $obj, 'each') {
        $obj->each(sub { $self->_add($_[0]) });
    } else {
        $self->_add($obj);
    }
}

sub delete {
    my ($self, $id) = @_;
    my $path = $self->path_to($id);
    $self->remove_path($path);
}

sub path_to {
    my ($self, $id) = @_;
    check_id($id);
    $id =~ s/[^0-9a-zA-Z]//g;
    my @path = unpack("(A2)*", $id);
    File::Spec->catdir($self->path, @path);
}

sub _create_path { # TODO error handling, owner, permissions
    my ($self, $path) = @_;
    File::Path::make_path($path);
}

sub _remove_path { # TODO error handling
    my ($self, $path) = @_;
    File::Path::remove_tree($path);
}

1;
