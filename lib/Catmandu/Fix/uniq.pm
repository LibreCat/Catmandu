package Catmandu::Fix::uniq;

use Catmandu::Sane;

our $VERSION = '1.2013';

use List::MoreUtils qw(uniq);
use Catmandu::Util::Path qw(as_path);
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path => (fix_arg => 1);

sub _build_fixer {
    my ($self) = @_;
    as_path($self->path)->updater(
        if_array_ref => sub {
            no warnings 'uninitialized';
            [List::MoreUtils::uniq(@{$_[0]})];
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::uniq - strip duplicate values from an array

=head1 SYNOPSIS

   # {tags => ["foo", "bar", "bar", "foo"]}
   uniq(tags)
   # {tags => ["foo", "bar"]}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
