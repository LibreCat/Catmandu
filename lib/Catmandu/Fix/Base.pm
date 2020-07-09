package Catmandu::Fix::Base;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Catmandu::Fix;
use Moo::Role;
use namespace::clean;

with 'Catmandu::Logger';
with 'Catmandu::Fix::Inlineable';
with 'Catmandu::Emit';

requires 'emit';

sub fix {
    my ($self, $data) = @_;
    Catmandu::Fix->new(fixes => [$self])->fix($data);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Base - Base role for all code emitting Catmandu fixes

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
