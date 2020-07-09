package Catmandu::Fix::index;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use List::MoreUtils qw(indexes first_index);
use namespace::clean;
use Catmandu::Fix::Has;

has path     => (fix_arg => 1);
has search   => (fix_arg => 1);
has multiple => (fix_opt => 1);

with 'Catmandu::Fix::Builder';

sub _build_fixer {
    my ($self) = @_;

    my $search = $self->search;
    my %args;
    if ($self->multiple) {
        %args = (
            if_string => sub {
                [indexes {$_ eq $search} unpack('(A)*', $_[0])];
            },
            if_array_ref => sub {
                [indexes {$_ eq $search} @{$_[0]}];
            },
        );
    }
    else {
        %args = (
            if_string => sub {
                index($_[0], $search);
            },
            if_array_ref => sub {
                first_index {$_ eq $search} @{$_[0]};
            },
        );
    }
    as_path($self->path)->updater(%args);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::index - Find all positions of a (sub)string in a field

=head1 SYNOPSIS

   # On strings, search the occurence of a character in a string

   # word => "abcde"
   index(word,'c')                   # word => 2
   index(word,'x')                   # word => -1

   # word => "abccde"
   index(word,'c', multiple:1)       # word => [2,3]

   # word => [a,b,bba] , loop over all word(s) with the '*'
   index(word.*,'a')                 # word -> [0,-1,2]

   # On arrays, search the occurence of a word in an array

   # words => ["foo","bar","foo"]
   index(words,'bar')                # words => 1
   index(words,'foo', multiple: 1)   # words => [0,2]

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
