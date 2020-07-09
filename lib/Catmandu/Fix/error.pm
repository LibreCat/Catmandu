package Catmandu::Fix::error;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util qw(is_value);
use Catmandu::Util::Path qw(:all);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has message => (fix_arg => 1);

sub _build_fixer {
    my ($self) = @_;
    my $msg = $self->message;
    if (looks_like_path($msg)) {
        my $getter = as_path($msg)->getter;
        sub {
            my $data = $_[0];
            my $vals = $getter->($data);
            @$vals || return $data;
            my $str = join "\n", grep {is_value($_)} @$vals;
            Catmandu::Error->throw($str);
        };
    }
    else {
        sub {Catmandu::Error->throw($msg)};
    }

}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::error - die with an error message

=head1 SYNOPSIS

  unless exists(id)
    error('id missing!')
  end

  # get the value from a path
  error($.error)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

