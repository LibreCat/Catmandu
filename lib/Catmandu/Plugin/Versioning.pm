package Catmandu::Plugin::Versioning;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(is_value check_value check_positive);
use Data::Compare;
use Moo::Role;

has version_bag => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_version_bag'
);

has version_compare_ignore => (
    is      => 'ro',
    lazy    => 1,
    default => sub { [qw(_version)] },
    coerce  => sub {
        my $keys = $_[0];
        $keys = [split /,/, $keys] if is_value $keys;
        push @$keys, '_version';
        $keys;
    },
);

has version_transfer => (
    is      => 'ro',
    lazy    => 1,
    default => sub { [] },
    coerce  => sub {
        my $keys = $_[0];
        $keys = [split /,/, $keys] if is_value $keys;
        $keys;
    },
);

sub _build_version_bag {
    $_[0]->store->bag($_[0]->name . '_version');
}

around add => sub {
    my ($sub, $self, $data) = @_;
    if (defined $data->{_id} and my $d = $self->get($data->{_id})) {
        $data->{_version} = $d->{_version} ||= 1;
        for my $key (@{$self->version_transfer}) {
            next if exists $data->{$key} || !exists $d->{$key};
            $data->{$key} = $d->{$key};
        }
        return $data
            if Compare($data, $d, {ignore_hash_keys => $self->version_compare_ignore});
        $self->version_bag->add({_id => "$data->{_id}.$data->{_version}", data => $d});
        $data->{_version}++;
    } else {
        $data->{_version} ||= 1;
    }
    $sub->($self, $data);
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
    check_value($id);
    check_positive($version);
    my $data = $self->version_bag->get("$id.$version") || return;
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

no Data::Compare;

1;
