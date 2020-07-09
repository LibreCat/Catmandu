package Catmandu::Fix::trim;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use Catmandu::Util qw(trim);
use Unicode::Normalize;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path => (fix_arg => 1);
has mode => (fix_arg => 1, default => sub {'whitespace'});

sub _build_fixer {
    my ($self) = @_;
    my $cb;
    if ($self->mode eq 'whitespace') {
        $cb = sub {
            trim($_[0]);
        };
    }
    elsif ($self->mode eq 'nonword') {
        $cb = sub {
            my $val = $_[0];
            $val =~ s/^\W+//;
            $val =~ s/\W+$//;
            $val;
        };
    }
    elsif ($self->mode eq 'diacritics') {
        $cb = sub {
            my $val = $_[0];
            $val = Unicode::Normalize::NFKD($val);
            $val =~ s/\p{NonspacingMark}//g;
            $val;
        };
    }
    as_path($self->path)->updater(if_string => $cb);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Catmandu::Fix::trim - trim leading and ending junk from the value of a field

=head1 SYNOPSIS

   # the default mode trims whitespace
   # e.g. foo => '   abc   ';

   trim(foo) # foo => 'abc';
   trim(foo, whitespace) # foo => 'abc';
   
   # trim non-word characters
   # e.g. foo => '   abc  / : .';
   trim(foo, nonword) # foo => 'abc';

   # trim accents
   # e.g. foo => 'français' ;
   trim(foo,diacritics) # foo => 'francais'
   
=head1 SEE ALSO

L<Catmandu::Fix>

=cut
