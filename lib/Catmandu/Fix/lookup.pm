package Catmandu::Fix::lookup;

use Catmandu::Sane;
use Catmandu::Importer::CSV;
use Moo;

with 'Catmandu::Fix::Base';

has path => (is => 'ro', required => 1);
has file => (is => 'ro', required => 1);
has opts => (is => 'ro', default => sub { +{} });
has dictionary => (is => 'ro', lazy => 1, builder => '_build_dictionary');

around BUILDARGS => sub {
    my ($orig, $class, $path, $file, %opts) = @_;
    $orig->($class, path => $path, file => $file, opts => \%opts);
};

sub _build_dictionary {
    my ($self) = @_;
    my %opts = %{$self->opts};
    delete $opts{'-delete'};
    delete $opts{'-default'};
    for my $key (keys %opts) {
        my $val = delete $opts{$key};
        $key =~ s/^-//;
        $opts{$key} = $val;
    }
    Catmandu::Importer::CSV->new(
        %opts,
        file => $self->file,
        header => 0,
        fields => ['key', 'val'],
    )->reduce({}, sub {
        my ($dict, $pair) = @_;
        $dict->{$pair->{key}} = $pair->{val};
        $dict;
    });
}

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;
    my $dict_var = $fixer->capture($self->dictionary);
    my $delete = $self->opts->{'-delete'};
    my $default = $self->opts->{'-default'};

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $val_var = shift;
            my $dict_val_var = $fixer->generate_var;
            my $perl = "my ${dict_val_var} = ${dict_var}->{${val_var}};" .
            "if (is_value(${val_var}) && is_value(${dict_val_var})) {" .
                "${val_var} = ${dict_val_var};" .
            "}";
            if ($delete) {
                $perl .= "else {" .
                    $fixer->emit_delete_key($var, $key) .
                "}";
            } elsif (defined $default) {
                $perl .= "else {" .
                    $fixer->emit_set_key($var, $key, $fixer->emit_value($default)) .
                "}";
            }
            $perl;
        });
    });
}

=head1 NAME

Catmandu::Fix::lookup - change the value of a HASH key or ARRAY index by looking up it's value in a dictionary

=head1 SYNOPSIS

   lookup('foo.bar', 'dictionary.csv');
   lookup('foo.bar', 'dictionary.csv', '-sep_char', '|');
   # delete value if the lookup fails:
   lookup('foo.bar', 'dictionary.csv', '-delete', 1);
   # use a default value if the lookup fails:
   lookup('foo.bar', 'dictionary.csv', '-default', 'default value');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
