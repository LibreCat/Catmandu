package Catmandu::Fix::replace_all;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data);
use Data::Dumper;
use Moo;

has path    => (is => 'ro', required => 1);
has key     => (is => 'ro', required => 1);
has search  => (is => 'ro', required => 1);
has replace => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $search, $replace) = @_;
    my ($p, $key) = parse_data_path($path);
    $orig->($class, path => $p, key => $key, search => $search, replace => $replace);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my $search  = $self->search;
    my $replace = $self->replace; 

    for my $match (grep ref, data_at($self->path, $data)) {
        set_data($match, $key,
            map { is_value($_) && s{$search}{$replace}g; $_ }
                get_data($match, $key));
    }

    $data;
}

sub emit {
    my ($self, $fixer) = @_;
    my $path_to_key = $self->path;
    my $key = $self->key;
    my $search = $self->search;
    my $replace = $self->replace;

    $fixer->emit_walk_path($fixer->var, $path_to_key, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            "if (is_value(${var})) {"
                ."utf8::upgrade(${var});"
                ."${var} =~ s{$search}{$replace}g;"
                ."}";
        });
    });
}

=head1 NAME

Catmandu::Fix::replace_all - search and replace using regex expressions

=head1 SYNOPSIS

   # Extract a substring out of the value of a field
   replace_all('year','\^','0');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
