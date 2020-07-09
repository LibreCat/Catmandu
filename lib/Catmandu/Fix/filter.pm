package Catmandu::Fix::filter;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Catmandu::Util qw(is_array_ref);
use Catmandu::Util::Regex qw(as_regex);
use Catmandu::Util::Path qw(as_path);
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path   => (fix_arg => 1);
has search => (fix_arg => 1);
has invert => (fix_opt => 1);

with 'Catmandu::Fix::Builder';

sub _build_fixer {
    my ($self) = @_;
    my $regex  = as_regex($self->search);
    my $cb     = $self->invert
        ? sub {
        [grep {!m/$regex/} @{$_[0]}];
        }
        : sub {
        [grep {m/$regex/} @{$_[0]}];
        };
    as_path($self->path)->updater(if_array_ref => $cb);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::filter - Filter values out of an array based on a regular expression

=head1 SYNOPSIS

   # words => ["Patrick","Nicolas","Paul","Frank"]
   filter(words,'Pa')
   # words => ["Patrick","Paul"]
   
   # filter only values that do NOT match the pattern:
   filter(words, 'Pa', invert: 1)
   # words => ["Nicolas","Frank"]

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
