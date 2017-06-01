package Catmandu::Store::MultiFiles::Index;

use Catmandu::Sane;

our $VERSION = '1.0507';

use Catmandu::Hits;
use Moo;
use Hash::Merge::Simple 'merge';
use namespace::clean;

with 'Catmandu::Store::Multi::Base', 'Catmandu::FileStore::Index';

around get => sub {
    my ( $orig, $class, @args ) = @_;

    if (my $store = $class->store->metadata) {
        my $result = {};
        my $bag_name = $class->store->metadata_bag;
        my $bag      = $store->bag($bag_name);
        my $metadata_item = $bag ? $bag->get(@args) : {};

        my $file_item = $class->$orig(@args);

        return unless $metadata_item || $file_item;

        merge $metadata_item , $file_item // +{};
    }
    else {
        return $class->$orig(@args);
    }
};

around add => sub {
    my ( $orig, $class, @args ) = @_;

    if (my $store = $class->store->metadata) {
        my $result = {};
        my $bag_name = $class->store->metadata_bag;
        my $bag      = $store->bag($bag_name);
        my $metadata_item = $bag ? $bag->add(@args) : {};

        my $file_item = $class->$orig(@args);

        return unless $metadata_item || $file_item;

        merge $metadata_item , $file_item // +{};
    }
    else {
        return $class->$orig(@args);
    }
};

around delete => sub {
    my ( $orig, $class, @args ) = @_;

    if (my $store = $class->store->metadata) {
        my $result = {};
        my $bag_name = $class->store->metadata_bag;
        my $bag      = $store->bag($bag_name);
        my $metadata_item = $bag ? $bag->delete(@args) : {};

        $class->$orig(@args);
    }
    else {
        return $class->$orig(@args);
    }
};

around delete_all => sub {
    my ( $orig, $class, @args ) = @_;

    if (my $store = $class->store->metadata) {
        my $result = {};
        my $bag_name = $class->store->metadata_bag;
        my $bag      = $store->bag($bag_name);
        my $metadata_item = $bag ? $bag->delete_all(@args) : {};

        $class->$orig(@args);
    }
    else {
        return $class->$orig(@args);
    }
};

around drop => sub {
    my ( $orig, $class, @args ) = @_;

    if (my $store = $class->store->metadata) {
        my $result = {};
        my $bag_name = $class->store->metadata_bag;
        my $bag      = $store->bag($bag_name);
        my $metadata_item = $bag ? $bag->drop(@args) : {};

        $class->$orig(@args);
    }
    else {
        return $class->$orig(@args);
    }
};

around commit => sub {
    my ( $orig, $class, @args ) = @_;

    if (my $store = $class->store->metadata) {
        my $result = {};
        my $bag_name = $class->store->metadata_bag;
        my $bag      = $store->bag($bag_name);
        my $metadata_item = $bag ? $bag->commit(@args) : {};

        $class->$orig(@args);
    }
    else {
        return $class->$orig(@args);
    }
};

1;

__END__

=pod

=head1 NAME

Catmandu::Store::MultiFiles::Index - Bag implementation for the MultiFiles store

=cut
