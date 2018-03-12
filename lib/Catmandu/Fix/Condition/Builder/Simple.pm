package Catmandu::Fix::Condition::Builder::Simple;

use Catmandu::Sane;

our $VERSION = '1.0606';

use List::MoreUtils qw(all_u any);
use Catmandu::Util::Path qw(as_path);
use Moo::Role;
use namespace::clean;

with 'Catmandu::Fix::Condition::Builder';

requires 'path';

has mode         => (is => 'lazy');
has value_tester => (is => 'lazy');

sub _build_mode {'all'}

sub _build_tester {
    my ($self) = @_;
    my $getter = as_path($self->path)->getter;
    my $mode   = $self->mode;
    my $tester = $self->value_tester;
    if ($mode eq 'all') {
        sub {
            all_u {$tester->($_)} @{$getter->($_[0])};
        };
    }
    elsif ($mode eq 'any') {
        sub {
            any {$tester->($_)} @{$getter->($_[0])};
        };
    }
}

1;
