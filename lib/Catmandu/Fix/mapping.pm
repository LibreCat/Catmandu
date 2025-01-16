package Catmandu::Fix::mapping;

use Catmandu::Sane;

use Catmandu::Importer::CSV;
use Catmandu::Util::Path qw(as_path);
use Catmandu::Util       qw(is_value);
use Clone                qw(clone);
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has file       => (fix_arg => 1);
has keep       => (fix_opt => 1);
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
    my ($self) = @_;

    my $dict = $self->dictionary;
    my $keep = $self->keep;

    sub {
        my $data = $_[0];

        foreach my $k (keys %$dict) {
            my $old_path = as_path($k);
            my $new_path = as_path($dict->{$k});

            my $getter  = $old_path->getter;
            my $deleter = $old_path->deleter;
            my $creator = $new_path->creator;

            my $values = [map {clone($_)} @{$getter->($data)}];
            $deleter->($data) unless $keep;
            $creator->($data, shift @$values) while @$values;
        }

        $data;
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::mapping - move several fields by a lookup table

=head1 SYNOPSIS

    # field_mapping.csv
    # AU,author
    # TI,title
    # PU,publisher
    # Y,year

    # fields found in the field_mapping.csv will be replaced
    # {AU => "Einstein"}
    mapping(field_mapping.csv)
    # {author => "Einstein"}

    # fields found in the field_mapping.csv with keep option will be copied
    # {AU => "Einstein"}
    mapping(field_mapping.csv, keep: 1)
    # {AU => => "Einstein", author => "Einstein"}

    # values not found will be kept
    # {foo => {bar => 232}}
    mapping(field_mapping.csv)
    # {foo => {bar => 232}}

    # in case you have a different seperator
    mapping(field_mapping.csv, sep_char: |)

=head1 SEE ALSO

L<Catmandu::Fix>, L<Catmandu::Fix::lookup>

=cut
