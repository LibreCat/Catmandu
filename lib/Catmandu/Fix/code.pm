package Catmandu::Fix::code;

use Catmandu::Sane;
use Catmandu::Util qw(is_code_ref);
use Moo;

has code => (
    is => 'ro', 
    default => sub { return sub { } },
    isa => sub {
        die "code must be a CODE reference" unless is_code_ref($_[0])
    }
);

around BUILDARGS => sub {
    my ($orig, $class, $code) = @_;
    $orig->($class, code => $code);
};

sub fix {
    my ($self, $data) = @_;
    $self->code->($data);
}

=head1 NAME

Catmandu::Fix::code - run arbitrary code as fix

=head1 SYNOPSIS

    my $fix = Catmandu::Fix::code->new( sub {
        my ($data) = @_;
        # ...do something
        return $data;
    });

=head1 SEE ALSO

L<Catmandu::Fix::cmd>

=cut

1;
