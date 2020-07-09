package Catmandu::Fix::to_json;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Cpanel::JSON::XS ();
use Catmandu::Util::Path qw(as_path);
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path => (fix_arg => 1);

sub _build_fixer {
    my ($self) = @_;
    my $json = Cpanel::JSON::XS->new->utf8(0)->pretty(0)->allow_nonref(1);
    as_path($self->path)->updater(
        if => [
            [qw(maybe_value array_ref hash_ref)] => sub {
                $json->encode($_[0]);
            }
        ]
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::to_json - convert the value of a field to json

=head1 SYNOPSIS

   to_json(my.field)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

