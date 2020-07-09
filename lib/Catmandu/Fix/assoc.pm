package Catmandu::Fix::assoc;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use Catmandu::Util qw(is_hash_ref);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path      => (fix_arg => 1);
has keys_path => (fix_arg => 1);
has vals_path => (fix_arg => 1);

sub _build_fixer {
    my ($self)      = @_;
    my $keys_getter = as_path($self->keys_path)->getter;
    my $vals_getter = as_path($self->vals_path)->getter;
    as_path($self->path)->creator(
        sub {
            my ($val, $data) = @_;
            if (is_hash_ref($val //= {})) {
                my $keys = $keys_getter->($data);
                my $vals = $vals_getter->($data);
                $val->{shift @$keys} = shift @$vals while @$keys && @$vals;
            }
            $val;
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::assoc - associate two values as a hash key and value

=head1 SYNOPSIS

   # {pairs => [{key => 'year', val => 2009}, {key => 'subject', val => 'Perl'}]}
   assoc(fields, pairs.*.key, pairs.*.val)
   # {fields => {subject => 'Perl', year => 2009}, pairs => [...]}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
