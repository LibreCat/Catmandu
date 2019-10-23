package Catmandu::Fix::disassoc;

use Catmandu::Sane;
use Catmandu::Util::Path qw(as_path);
use Catmandu::Util qw(is_array_ref);
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has old_path   => (fix_arg => 1);
has new_path   => (fix_arg => 1);
has key_name   => (fix_arg => 1);
has value_name => (fix_arg => 1);

sub _build_fixer {
    my ($self)   = @_;
    my $key_name = $self->key_name;
    my $val_name = $self->value_name;
    my $getter   = as_path($self->old_path)->getter;
    my $creator  = as_path($self->new_path)->creator;
    as_path($self->new_path)->creator(
        sub {
            my ($arr, $data) = @_;
            if (is_array_ref($arr //= [])) {
                for my $hash (@{$getter->($data)}) {
                    for my $key (sort keys %$hash) {
                        push @$arr,
                            {$key_name => $key, $val_name => $hash->{$key},};
                    }
                }
            }
            $arr;
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::disassoc - inverse of assoc, transform a hash into an array of key value pairs

=head1 SYNOPSIS

   # {fields => {subject => 'Perl', year => 2009}}
   disassoc(fields, pairs, key, val)
   # {pairs => [{key => 'year', val => 2009}, {key => 'subject', val => 'Perl'}], fields => ...}

=head1 SEE ALSO

L<Catmandu::Fix::assoc>, L<Catmandu::Fix>

=cut
