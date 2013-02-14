package Catmandu::Fix::substring;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data);
use Moo;

has path => (is => 'ro', required => 1);
has key  => (is => 'ro', required => 1);
has args => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, @args) = @_;
    my ($p, $key) = parse_data_path($path);
    $orig->($class, path => $p, key => $key, args => [@args]);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my $args = $self->args;
    for my $match (grep ref, data_at($self->path, $data)) {
        set_data($match, $key,
            map { is_string($_) ? mysubstr($_, @$args) : $_ }
                get_data($match, $key));
    }

    $data;
}

sub mysubstr {
    if    (@_ == 2) { substr($_[0], $_[1]) }
    elsif (@_ == 3) { substr($_[0], $_[1], $_[2]) }
    elsif (@_ == 4) { substr($_[0], $_[1], $_[2], $_[3]) }
    else { confess "wrong number of arguments" }
}

sub emit {
    my ($self, $fixer) = @_;
    my $path_to_key = $self->path;
    my $key = $self->key;
    my $args = $self->args;
    my $str_args = @$args > 1 ? join(", ", @$args[0, 1]) : $args->[0];

    $fixer->emit_walk_path($fixer->var, $path_to_key, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            if (@$args < 3) {
                return "${var} = substr(as_utf8(${var}), ${str_args}) if is_value(${var});";
            }
            my $replace = $fixer->emit_string($args->[2]);
            "if (is_value(${var})) {"
                ."utf8::upgrade(${var});"
                ."substr(${var}, ${str_args}) = ${replace};"
                ."}";
        });
    });
}

=head1 NAME

Catmandu::Fix::substring - extract a substring out of the value of a field

=head1 SYNOPSIS

   # Extract a substring out of the value of a field
   substring('initials',0,1);

=head1 SEE ALSO

L<Catmandu::Fix>, substr

=cut

1;
