package Catmandu::Fix::Bind::visitor;

use Catmandu::Sane;

our $VERSION = '1.0604';

use Moo;
use Catmandu::Util;
use namespace::clean;

with 'Catmandu::Fix::Bind', 'Catmandu::Fix::Bind::Group';

has path => (is => 'ro');

sub unit {
    my ($self, $data) = @_;

    if (defined $self->path) {
        return Catmandu::Util::data_at($self->path, $data);
    }
    else {
        return $data;
    }
}

sub bind {
    my ($self, $mvar, $func) = @_;

    if (Catmandu::Util::is_array_ref($mvar)) {
        return $self->bind_array($mvar, $func, '');
    }
    elsif (Catmandu::Util::is_hash_ref($mvar)) {
        return $self->bind_hash($mvar, $func, '');
    }
    else {
        return $self->bind_hash($mvar, $func, '');
    }
}

sub bind_scalar {
    my ($self, $mvar, $func, $parent) = @_;

    return $func->({'key' => $parent, 'scalar' => $mvar})->{'scalar'};
}

sub bind_array {
    my ($self, $mvar, $func, $parent) = @_;

    $mvar = $func->({'key' => $parent, 'array' => $mvar})->{'array'};

    my $new_var = [];

    for (my $i = 0; $i < @$mvar; $i++) {
        my $item = $mvar->[$i];
        if (Catmandu::Util::is_array_ref($item)) {
            $mvar->[$i] = $self->bind_array($item, $func, $i);
        }
        elsif (Catmandu::Util::is_hash_ref($item)) {
            $mvar->[$i] = $self->bind_hash($item, $func, $i);
        }
        else {
            $mvar->[$i]
                = $func->({'key' => $i, 'scalar' => $item})->{'scalar'};
        }
    }

    return $mvar;
}

sub bind_hash {
    my ($self, $mvar, $func, $parent) = @_;

    $mvar = $func->({'key' => $parent, 'hash' => $mvar})->{'hash'};

    for my $key (keys %$mvar) {
        my $item = $mvar->{$key};

        if (Catmandu::Util::is_array_ref($item)) {
            $mvar->{$key} = $self->bind_array($item, $func, $key);
        }
        elsif (Catmandu::Util::is_hash_ref($item)) {
            $mvar->{$key} = $self->bind_hash($item, $func, $key);
        }
        else {
            $mvar->{$key}
                = $func->({'key' => $key, 'scalar' => $item})->{'scalar'};
        }
    }

    return $mvar;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Bind::visitor - a binder that computes Fix-es for every element in record

=head1 SYNOPSIS

 # If data is like:

   numbers:
      - one
      - two
      - three
   person:
      name: jennie
      age: 44
      color:
         - green
         - purple
         - brown
         - more:
            foo: bar

 do visitor()
    upcase(scalar)  # upcase every scalar value in the record
 end

 # will produce

   numbers:
      - ONE
      - TWO
      - THREE
   person:
      name: JENNIE
      age: 44
      color:
         - GREEN
         - PURPLE
         - BROWN
         - more:
            foo: BAR

  do visitor()
    # upcase all the 'name' fields in the record
    if all_match(key,name)
      upcase(scalar)
    end
  end

=head1 DESCRIPTION

The visitor binder will iterate over all the elements in a record and perform fixes on them.

Special node names are available to process every visited element:

=over 4

=item scalar

Process a Fix on every scalar value. E.g.

   upcase(scalar)
   replace_all(scalar,'$','tested')

=item array

Process a Fix on every array value. E.g.

   sort_field(array)

Values need to be put in the 'array' field to be available for fixes. The scope of
the array is limited to the array visited.

=item hash

Process a Fix on every hash value. E.g.

   copy_field(hash.age,hash.age2)

Values need to be put in the 'hash' field to be available for fixes. The scope of
the hash is limited to the hash visited.

=item key

Provides access to the key on which the scalar,array or hash value is found. Eg.

   # Upcase all 'name' fields in the record
   if all_match(key,name)
      upcase(scalar)
   end

=back

=head1 CONFIGURATION

=head2 path

A path in the data to visit:

  # Visit any field
  do visitor()
    ...
  end

  # Visit only the fields at my.deep.field
  do visitor(-path => my.deep.field )
    ...
  end

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut
