package Catmandu::Fix::lookup;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Catmandu::Importer::CSV;
use Catmandu::Util::Path qw(as_path);
use Catmandu::Util qw(is_value);
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path       => (fix_arg => 1);
has file       => (fix_arg => 1);
has default    => (fix_opt => 1, predicate => 1);
has delete     => (fix_opt => 1);
has csv_args   => (fix_opt => 'collect');
has dictionary => (is      => 'lazy', init_arg => undef);

sub _build_dictionary {
    my ($self) = @_;
    Catmandu::Importer::CSV->new(
        %{$self->csv_args},
        file   => $self->file,
        header => 0,
        fields => ['key', 'val'],
    )->reduce(
        {},
        sub {
            my ($dict, $pair) = @_;
            $dict->{$pair->{key}} = $pair->{val};
            $dict;
        }
    );
}

sub _build_fixer {
    my ($self)      = @_;
    my $path        = as_path($self->path);
    my $dict        = $self->dictionary;
    my $has_default = $self->has_default;
    my $default     = $self->default;
    my $delete      = $self->delete;
    $path->updater(
        sub {
            my $val = $_[0];
            if (is_value($val) && defined(my $new_val = $dict->{$val})) {
                return $new_val;
            }
            elsif ($delete) {
                return undef, 1, 1;
            }
            elsif ($has_default) {
                return $default;
            }
            return undef, 1, 0;
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::lookup - change the value of a HASH key or ARRAY index by
looking up its value in a dictionary

=head1 SYNOPSIS

    # dictionary.csv
    # id,planet
    # 1,sun
    # 2,earth
    # 3,moon

    # values found in the dictionary.csv will be replaced
    # {foo => {bar => 2}}
    lookup(foo.bar, dictionary.csv)
    # {foo => {bar => 'earth'}}

    # values not found will be kept
    # {foo => {bar => 232}}
    lookup(foo.bar, dictionary.csv)
    # {foo => {bar => 232}}

    # in case you have a different seperator
    lookup(foo.bar, dictionary.csv, sep_char: |)

    # delete value if the lookup fails:
    lookup(foo.bar, dictionary.csv, delete: 1)

    # use a default value if the lookup fails:
    lookup(foo.bar, dictionary.csv, default: 'default value')

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
