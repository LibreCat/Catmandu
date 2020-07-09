package Catmandu::Path;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Catmandu::Util qw(is_array_ref is_code_ref);
use Moo::Role;

has path => (is => 'ro', required => 1);

requires 'getter';
requires 'setter';
requires 'creator';
requires 'updater';
requires 'deleter';

around creator => sub {
    my $orig = shift;
    my $self = shift;
    my %opts = @_ == 1 ? (value => $_[0]) : @_;

    $orig->($self, %opts);
};

around updater => sub {
    my $orig = shift;
    my $self = shift;
    my %opts = @_ == 1 ? (value => $_[0]) : @_;

    for my $key (keys %opts) {
        my $val = $opts{$key};
        next unless $key =~ s/^if_//;
        push @{$opts{if} ||= []}, $key, $val;
    }

    if (my $tests = $opts{if}) {
        for (my $i = 0; $i < @$tests; $i += 2) {
            my $test = $tests->[$i];
            $test = [$test] unless is_array_ref($test);
            $tests->[$i]
                = [map {is_code_ref($_) ? $_ : Catmandu::Util->can("is_$_")}
                    @$test];
        }
    }

    $orig->($self, %opts);
};

1;

__END__

=pod

=head1 NAME

Catmandu::Path - Base role for Catmandu path implementations

=head1 SEE ALSO

L<Catmandu::Path::simple>.

=cut
