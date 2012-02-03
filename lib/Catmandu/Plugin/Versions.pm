package Catmandu::Plugin::Versions;

use Catmandu::Sane;
use Catmandu::Util qw(:check);
use Moo::Role;

has versions_bag => (is => 'ro', lazy => 1, builder => '_build_versions_bag');

sub _build_versions_bag {
    my $self = $_[0];
    $self->store->bag($self->name . '_version');
}

before add => sub {
    my ($self, $data) = @_;
    my $id = $data->{_id} ||= $self->generate_id;
    my $version = 1;
    if (my $d = $self->get($id)) {
        $version = $d->{_version} ||= 1;
        $self->versions_bag->add({_id => "$data->{_id}.$version", data => $d});
        $version++;
    }
    $data->{_version} = $version;
};

sub get_history {
    my ($self, $id, %opts) = @_;
    if (my $data = $self->get($id)) {
        my $history = [$data];
        my $version = $data->{_version} || 1;
        while (--$version) {
            push @$history, $self->get_version($id, $version);
        }
        return $history;
    }
    return;
}

sub get_version {
    my ($self, $id, $version) = @_;
    check_string($id);
    check_positive($version);
    my $data = $self->versions_bag->get("$id.$version") || return;
    $data->{data};
}

sub restore_version {
    my ($self, $id, $version) = @_;
    if (my $data = $self->get_version($id, $version)) {
        return $self->add($data);
    }
    return;
}

sub get_previous_version {
    my ($self, $id) = @_;
    if (my $data = $self->get($id)) {
        my $version = $data->{_version} || 1;
        if ($version > 1) {
            return $self->get_version($id, $version - 1);
        }
    }
    return;
}

sub restore_previous_version {
    my ($self, $id) = @_;
    if (my $data = $self->get_previous_version($id)) {
        return $self->add($data);
    }
    return;
}

1;
