package Catmandu::Exporter::JSON;

use 5.010;
use strict;
use warnings;
use Carp;
use Scalar::Util;
use JSON;

sub open {
    my ($pkg, $file) = @_;
    bless {
        file => $file,
    }, $pkg;
}

sub write {
    my ($self, $obj) = @_;

    my $file = $self->{file};
    my $size = 0;

    given (ref $obj) {
        when ('ARRAY') {
            print $file encode_json($obj);
            $size = scalar @$obj;
        }
        when ('HASH') {
            print $file encode_json($obj);
            $size = 1;
        }
        when (Scalar::Util::blessed($obj) && $obj->can('each')) {
            print $file '[';
            $obj->each(sub {
                print $file ',' if $size;
                print $file encode_json(shift);
                $size += 1;
            });
            print $file ']';
        }
        default {
            croak "Can't export";
        }
    }

    $size;
}

sub close {
    1;
}

1;

__END__

=head1 NAME

 Catmandu::Exporter::JSON - [FILL IN THE PURPOSE]

=head1 SYNOPSIS

 [FILL IN EXAMPLE USAGE]

=head1 DESCRIPTION

 [FILL IN TEXTUAL DESCRIPTION OF THIS PACKAGE]

=head1 METHODS

=over 4

=item method1

[DOCUMENTATION]

=item method2

[DOCUMENTATION]

=back

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
