package Catmandu::Plugin::Versioning;

use Catmandu::Sane;
use Catmandu::Util qw(is_value check_string check_positive);
use Data::Compare ();
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
        my $ignore = $_[0];
        $ignore = [split /,/, $ignore] if is_value $ignore;
        push @$ignore, '_version';
        $ignore;
    },
);

sub _build_version_bag {
    $_[0]->store->bag($_[0]->name . '_version');
}

around add => sub {
    my ($sub, $self, $data) = @_;
    my $id = $data->{_id} //= $self->generate_id($data);
    if (my $d = $self->get($id)) {
        $data->{_version} = $d->{_version} ||= 1;
        return $data
            if Data::Compare::Compare($data, $d, {ignore_hash_keys => $self->version_compare_ignore});
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
    check_string($id);
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

1;
