package Catmandu::Fix::Bind::hashmap;

use Moo;
use Catmandu::Util qw(:is);
use namespace::clean;

with 'Catmandu::Fix::Bind';

has exporter => (is => 'ro' , default => sub { 'JSON' });
has store    => (is => 'ro');
has unqiue   => (is => 'ro' , default => sub { 0 });
has count    => (is => 'ro');
has join     => (is => 'ro');
has hash     => (is => 'lazy');

sub _build_hash {
    +{};
}

sub add_to_hash {
    my ($self,$key,$val) = @_;
    if ($self->count) {
        $self->hash->{$key} += 1;
    }
    elsif ($self->unqiue) {
        $self->hash->{$key}->{$val} = 1;
    }
    else {
        push @{$self->hash->{$key}}  , $val;
    }
}

sub bind {
    my ($self,$data,$code,$name) = @_;

    $data = $code->($data);

    my $key   = $data->{key};
    my $value = $data->{value};

    if (defined $key) {
        if (is_string($key)) {
            $self->add_to_hash($key,$value);
        }
        elsif (is_array_ref($key)) {
            for (@$key) {
                $self->add_to_hash($_,$value);
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

    if ($self->store) {
        $e = Catmandu->store($self->store);
    }
    else {
        $e = Catmandu->exporter($self->exporter);
    }

    my $id = 0;
    for (sort keys %$h) {
        my $v;

        if ($self->count) {
            $v = $h->{$_};
        }
        elsif ($self->unqiue) {
            $v = [ keys %{$h->{$_}} ];
        }
        else {
            $v = $h->{$_};
        }

        if (is_array_ref($v) && $self->join) {
            $v = join $self->join , @$v;
        }


        $e->add({ _id => $_ ,  value => $v });
    }

    $e->commit;
}

=head1 NAME

Catmandu::Fix::Bind::hashmap - a binder to add key/value pairs to an internal hashmap

=head1 SYNOPSIS

 # Find all ISBN in a stream
 do hashmap(exporter => JSON, join => ',')
   # Need an identity binder to group all operations that calculate key_value pairs
   do identity()
    copy_field(isbn,key)
    copy_field(_id,value)
   end
 end

 # will export to the YAML exporter a hash map containing all isbn occurrences in the stream

 { "_id": "ISBN1" , "value": "0121,12912,121" }
 { "_id": "ISBN2" , "value": "102012" }

 # Count the number of ISBN occurrences in a stream
 # File: count.fix:
 do hashmap(count: 1)
   do identity()
    copy_field(isbn,key)
   end
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

The name of an exporter to send the results to. Default: JSON

=head2 store: STORE

Send the output to a store instead of an exporter.

=head2 unique: 0|1

All the values for the a key will be unique.

=head2 join: CHAR

Join all the values of a key using a delimiter.

=head2 count: 0|1

Don't store the values only count the number of key occurences.

=head1 AUTHOR

Patrick Hochstenbach - L<Patrick.Hochstenbach@UGent.be>

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut

1;
