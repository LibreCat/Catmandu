package Catmandu::Fix::Base;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Catmandu::Fix;
use Scalar::Util qw(weaken);
use Moo::Role;
use namespace::clean;

with 'Catmandu::Fix::Inlineable', 'Catmandu::Logger';

requires 'emit';

sub fixer {
    my ($self) = @_;
    Catmandu::Fix->new(fixes => [$self]);
}

sub fix {
    my ($self, $data) = @_;
    $self->fixer->fix($data);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Base - Base class for all code emitting Catmandu fixes

=head1 SYNOPSIS

    package Catmandu::Fix::my_fix;

    use Catmandu::Sane;
    use Moo;

    with 'Catmandu::Fix::Base';

    sub emit {
        my ($self, $fixer) = @_;
        ....FIXER GENERATING CODE....
    }

=head1 SEE ALSO

For more information how to create fixes read the following two blog posts:

http://librecat.org/catmandu/2014/03/14/create-a-fixer.html
http://librecat.org/catmandu/2014/03/26/creating-a-fixer-2.html
=cut
