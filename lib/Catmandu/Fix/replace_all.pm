package Catmandu::Fix::replace_all;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use Catmandu::Util::Regex qw(substituter);
use namespace::clean;
use Catmandu::Fix::Has;

has path    => (fix_arg => 1);
has search  => (fix_arg => 1);
has replace => (fix_arg => 1);

with 'Catmandu::Fix::Builder';

sub _build_fixer {
    my ($self) = @_;
    as_path($self->path)
        ->updater(if_value => substituter($self->search, $self->replace));
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::replace_all - search and replace using regex expressions

=head1 SYNOPSIS

   # Extract a substring out of the value of a field
   # {author => "tom jones"}
   replace_all(author, '([^ ]+) ([^ ]+)', '$2, $1')
   # {author => "jones, tom"}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
