package Catmandu::Fix::from_json;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Cpanel::JSON::XS ();
use Moo;
use Catmandu::Util::Path qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path => (fix_arg => 1);

sub _build_fixer {
    my ($self) = @_;
    my $json = Cpanel::JSON::XS->new->utf8(0)->pretty(0)->allow_nonref(1);
    as_path($self->path)->updater(if_string => sub {$json->decode($_[0])});
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::from_json - replace a json field with the parsed value

=head1 SYNOPSIS

   from_json(my.field)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut


