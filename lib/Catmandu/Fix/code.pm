package Catmandu::Fix::code;

use Catmandu::Sane;

our $VERSION = '1.0605';

use Catmandu::Util qw(check_code_ref);
use Moo;

with 'Catmandu::Fix::Inlineable';

has code => (
    is      => 'ro',
    default => sub {
        return sub { }
    },
    isa => \&check_code_ref,
);

around BUILDARGS => sub {
    my ($orig, $class, $code) = @_;
    $orig->($class, code => $code);
};

sub fix {
    my ($self, $data) = @_;
    $self->code->($data);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::code - run arbitrary code as fix

=head1 SYNOPSIS

    my $fix = Catmandu::Fix::code->new( sub {
        my ($data) = @_;
        # ...do something
        return $data;
    });

=head1 SEE ALSO

L<Catmandu::Fix::perlcode>, L<Catmandu::Fix::cmd>

=cut
