package Catmandu::Fix::lookup_in_store;

use Catmandu::Sane;

our $VERSION = '1.06';

use Catmandu;
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path       => (fix_arg => 1);
has store_name => (fix_arg => 1);
has bag_name   => (fix_opt => 1, init_arg => 'bag');
has default    => (fix_opt => 1);
has delete     => (fix_opt => 1);
has store_args => (fix_opt => 'collect');
has store      => (is      => 'lazy', init_arg => undef);
has bag        => (is      => 'lazy', init_arg => undef);

sub _build_store {
    my ($self) = @_;
    Catmandu->store($self->store_name, %{$self->store_args});
}

sub _build_bag {
    my ($self) = @_;
    defined $self->bag_name
        ? $self->store->bag($self->bag_name)
        : $self->store->bag;
}

sub emit {
    my ($self, $fixer) = @_;
    my $path    = $fixer->split_path($self->path);
    my $key     = pop @$path;
    my $bag_var = $fixer->capture($self->bag);
    my $delete  = $self->delete;
    my $default = $self->default;

    $fixer->emit_walk_path(
        $fixer->var,
        $path,
        sub {
            my $var = shift;
            $fixer->emit_get_key(
                $var, $key,
                sub {
                    my $val_var     = shift;
                    my $val_index   = shift;
                    my $bag_val_var = $fixer->generate_var;
                    my $perl
                        = "if (is_value(${val_var}) && defined(my ${bag_val_var} = ${bag_var}->get(${val_var}))) {"
                        . "${val_var} = ${bag_val_var};" . "}";
                    if ($delete) {
                        $perl .= "else {";
                        if (defined $val_index)
                        { # wildcard: only delete the value where the lookup failed
                            $perl .= "splice(\@{${var}}, ${val_index}--, 1);";
                        }
                        else {
                            $perl .= $fixer->emit_delete_key($var, $key);
                        }
                        $perl .= "}";
                    }
                    elsif (defined $default) {
                        $perl
                            .= "else {"
                            . "${val_var} = "
                            . $fixer->emit_value($default) . ";" . "}";
                    }
                    $perl;
                }
            );
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::lookup_in_store - change the value of a HASH key or ARRAY index
by looking up its value in a store

=head1 SYNOPSIS

   # Lookup in an SQLLite database
   lookup_in_store(foo.bar, DBI, data_source: "dbi:SQLite:path/data.sqlite")

   # Lookup in a MongoDB database
   lookup_in_store(foo.bar, MongoDB, database_name: lookups, bag: mydata)

   # Lookup in a MongoDB database, using the default bag and a default value when nothing found
   lookup_in_store(foo.bar, MongoDB, database_name: lookups, default: 'default value')

   # Lookup in a MongoDB database, using the default bag and delete the foo.bar field when nothing found
   lookup_in_store(foo.bar, MongoDB, database_name: lookups, delete: 1)

=head1 DESCRIPTION

=head2 lookup_in_store(PATH,STORE[,store_param: store_val, ...][,bag: bag_name][,delete:1][,default:value])

Use the lookup_in_store fix to match a field in a record to the "_id" field in
a Catmandu::Store of choice.  For instance, if a Catmandu::Store contains these
records:

    ---
    _id: water
    fr: l'eau
    de: wasser
    en: water
    nl: water
    ---
    _id: tree
    fr: arbre
    de: baum
    en: tree
    nl: boom

And you data contains these fields:

    ---
    _id: 001
    tag: tree
    ---
    _id: 002
    tag: water

Then, the fix below will lookup a tag in the Catmandu::Store and replace it
with the database value:

    lookup_in_store(tag, DBI, data_source: "dbi:SQLite:path/data.sqlite")

The resulting data will contain:

    ---
    _id: 001
    tag:
      _id: tree
      fr: arbre
      de: baum
      en: tree
      nl: boom
    ---
    _id: 002
    tag:
      _id: water
      fr: l'eau
      de: wasser
      en: water
      nl: water

=head1 SEE ALSO

L<Catmandu::Fix>, L<Catmandu::Store> , L<Catmandu::Fix::add_to_store>

=cut

