package Catmandu::Fix::Bind::hashmap;

use Catmandu::Sane;

our $VERSION = '1.2013';

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

 # Find non unique ISBN numbers in the record stream
 do hashmap(join: ',')
    copy_field(isbn,key)
    copy_field(_id,value)
 end

 # will export to the JSON exporter a hash map containing all isbn occurrences in the stream

 { "_id": "9781565920422" , "value": "rec0001,rec0329,rec1032" }
 { "_id": "9780596004927" , "value": "rec0718" }

 # Ignore the values. Count the number of ISBN occurrences in a stream
 # File: count.fix:
 do hashmap(count: 1)
    copy_field(isbn,key)
 end

 # Use the Null exporter to suppress the normal output
 $ cat /tmp/data.json | catmandu convert JSON --fix count.fix to Null

=head1 DESCRIPTION

The hashmap binder will insert all key/value pairs given to a internal hashmap
that can be exported using an Catmandu::Exporter.

The 'key' fields in the internal hashmap will be exported as '_id' field.

If the key in the hashmap Bind is an ARRAY, then multiple key/value pairs will
be inserted into the hashmap.

By default all the values will be added as an array to the hashmap. Every key
will have one or more values. Use the 'join' parameter to create a string
out of this array.

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

When set to 1, then all values in the key 'value' will be made unique

=head2 join: CHAR

Join all the values of a key using a delimiter.

=head2 count: 0|1

Don't store the values only count the number of key occurrences.

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut
