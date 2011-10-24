package Catmandu::Collection;
use Catmandu::Sane;
use parent qw(Catmandu::Pluggable);
use Catmandu::Object store => 'r', name => 'r';
use Catmandu::Util qw(quacks ensure_id assert_id ensure_collection);

sub each    { confess 'not implemented' }
sub _get    { confess 'not implemented' }
sub _add    { confess 'not implemented' }
sub _delete { confess 'not implemented' }

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
    ensure_collection($obj, $self->name);
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
    if (quacks $obj, 'each') {
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
    return;
}

1;
