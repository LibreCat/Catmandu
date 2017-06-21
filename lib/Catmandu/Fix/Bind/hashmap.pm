package Catmandu::Fix::Bind::hashmap;

use Catmandu::Sane;

our $VERSION = '1.06';

use Moo;
use Catmandu::Util qw(:is);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Bind', 'Catmandu::Fix::Bind::Group';

has exporter   => (fix_opt => 1);
has store      => (fix_opt => 1);
has uniq       => (fix_opt => 1, default => sub {0});
has count      => (fix_opt => 1);
has join       => (fix_opt => 1);
has extra_args => (fix_opt => 'collect');
has hash       => (is      => 'lazy');

sub _build_hash {
    +{};
}

sub add_to_hash {
    my ($self, $key, $val) = @_;
    if ($self->count) {
        $self->hash->{$key} += 1;
    }
    elsif ($self->uniq) {
        $self->hash->{$key}->{$val} = 1;
    }
    else {
        push @{$self->hash->{$key}}, $val;
    }
}

sub bind {
    my ($self, $data, $code) = @_;

    $data = $code->($data);

    my $key   = $data->{key};
    my $value = $data->{value};

    if (defined $key) {
        if (is_string($key)) {
            $self->add_to_hash($key, $value);
        }
        elsif (is_array_ref($key)) {
            for (@$key) {
                $self->add_to_hash($_, $value);
            }
        }
        else {
            warn "$key is not a string or array for $value";
        }
    }

    $data;
}

sub DESTROY {
    my ($self) = @_;
    my $h = $self->hash;
    my $e;
    my $args = $self->extra_args // {};

    if ($self->store) {
        $e = Catmandu->store($self->store, %$args);
    }
    elsif ($self->exporter) {
        $e = Catmandu->exporter($self->exporter, %$args);
    }
    else {
        $e = Catmandu->exporter('JSON', line_delimited => 1);
    }

    my $sorter = $self->count ? sub {$h->{$b} <=> $h->{$a}} : sub {$a cmp $b};

    my $id = 0;
    for (sort $sorter keys %$h) {
        my $v;

        if ($self->count) {
            $v = $h->{$_};
        }
        elsif ($self->uniq) {
            $v = [sort keys %{$h->{$_}}];
        }
        else {
            $v = $h->{$_};
        }

        if (is_array_ref($v) && $self->join) {
            $v = join $self->join, @$v;
        }

        $e->add({_id => $_, value => $v});
    }

    $e->commit;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Bind::hashmap - a binder to add key/value pairs to an internal hashmap

=head1 SYNOPSIS

 # Find all ISBN in a stream
 do hashmap(exporter: JSON, join: ',')
    copy_field(isbn,key)
    copy_field(_id,value)
 end

 # will export to the YAML exporter a hash map containing all isbn occurrences in the stream

 { "_id": "ISBN1" , "value": "0121,12912,121" }
 { "_id": "ISBN2" , "value": "102012" }

 # Count the number of ISBN occurrences in a stream
 # File: count.fix:
 do hashmap(count: 1)
    copy_field(isbn,key)
 end

 # Use the Null exporter to suppress the normal output
 $ cat /tmp/data.json | catmandu convert JSON --fix count.fix to Null

=head1 DESCRIPTION

The hashmap binder will insert all key/value pairs given to a internal hashmap that can be exported
using an Catmandu::Exporter.

If the key is an ARRAY, then multiple key/value pairs will be inserted into the hashmap.

By default all the values will be added as an array to the hashmap. Every key will have one
or more values.

=head1 CONFIGURATION

=head2 exporter: EXPORTER

The name of an exporter to send the results to. Default: JSON  Extra parameters can be added:

    do hashmap(exporter: JSON, file:/tmp/data.json, count: 1)
      ...
    end

=head2 store: STORE

Send the output to a store instead of an exporter. Extra parameters can be added:

    do hashmap(store: MongoDB, database_name: test, bag: data, count: 1)
      ...
    end

=head2 uniq: 0|1

All the values for the a key will be unique.

=head2 join: CHAR

Join all the values of a key using a delimiter.

=head2 count: 0|1

Don't store the values only count the number of key occurrences.

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut
