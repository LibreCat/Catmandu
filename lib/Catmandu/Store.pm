package Catmandu::Store;
use Catmandu::Sane;
use Catmandu::Object;
use Catmandu::Util qw(load_package ensure_id assert_id);

sub each    { confess 'not implemented' }
sub _get    { confess 'not implemented' }
sub _add    { confess 'not implemented' }
sub _delete { confess 'not implemented' }

sub _build {
    my ($self, $args) = @_;
    my $plugins = $args->{plugins} || [];
    $self->{plugins} = [ map { load_package($_, 'Catmandu::Plugin::Store')->new($self) } @$plugins ];
}

sub plugins {
    if (wantarray) {
        return @{$_[0]->{plugins}};
    }
    $_[0]->{plugins};
}

sub get {
    my ($self, $id) = @_;
    my $obj = $self->_get(assert_id($id)) || return;
    for my $plugin ($self->plugins) {
        $plugin->after_get($self, $obj);
    }
    $obj;
}

sub _add_single {
    my ($self, $obj) = @_;
    ensure_id($obj);
    for my $plugin ($self->plugins) {
        $plugin->before_add($self, $obj);
    }
    $self->_add($obj);
    for my $plugin ($self->plugins) {
        $plugin->after_add($self, $obj);
    }
    $obj;
}

sub add {
    my ($self, $obj) = @_;
    if (quack $obj, 'each') {
        $obj->each(sub {
            $self->_add_single($_[0]);
        });
    } else {
        $self->_add_single($obj);
    }
}

sub delete {
    my ($self, $id) = @_;
    $id = assert_id($id);
    for my $plugin ($self->plugins) {
        $plugin->before_delete($self, $id);
    }
    $self->_delete($id);
    $id;
}

1;
