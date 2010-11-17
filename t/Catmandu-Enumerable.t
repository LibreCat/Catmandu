use Test::More tests => 31;

BEGIN { use_ok 'Catmandu::Enumerable'; }
require_ok 'Catmandu::Enumerable';

package T::Enumerable;

use Moose;

with 'Catmandu::Enumerable';

has data => (is => 'rw', isa => 'ArrayRef');

sub each {
    my ($self, $sub) = @_;
    my $data = $self->data;
    $sub->($_) for @$data;
    scalar @$data;
}

package main;

my $enum = T::Enumerable->new(data => [1,2,3]);

is_deeply $enum->to_array, [1,2,3];
is $enum->all(sub { $_ > 0 }), 1;
is $enum->all(sub { $_ > 1 }), 0;

is $enum->any(sub { $_ < 3 }), 1;
is $enum->any(sub { $_ > 3 }), 0;

is $enum->many(sub { $_ < 3 }), 1;
is $enum->many(sub { $_ < 2 }), 0;

is_deeply $enum->map(sub { $_ + 1 }), [2,3,4];

is $enum->detect(sub { $_ == 3 }), 3;
is $enum->detect(sub { $_ == 4 }), undef;

is_deeply $enum->select(sub { $_ < 1 }), [];
is_deeply $enum->select(sub { $_ > 1 }), [2,3];

is_deeply $enum->reject(sub { $_ < 2 }), [2,3];
is_deeply $enum->reject(sub { $_ > 0 }), [];

is_deeply $enum->partition(sub { $_ < 1 }), [[],[1,2,3]];
is_deeply $enum->partition(sub { $_ < 2 }), [[1],[2,3]];
is_deeply $enum->partition(sub { $_ < 3 }), [[1,2],[3]];
is_deeply $enum->partition(sub { $_ < 4 }), [[1,2,3],[]];

is $enum->reduce(sub { my ($memo, $num) = @_; $memo + $num; }), 6;
is $enum->reduce(1, sub { my ($memo, $num) = @_; $memo + $num; }), 7;
is_deeply $enum->reduce({}, sub { my ($memo, $num) = @_; $memo->{$num} = $num + 1; $memo; }), {1=>2,2=>3,3=>4};

is $enum->first, 1;
is_deeply $enum->first(1), [1];

is_deeply $enum->take(1), [1];
is_deeply $enum->take(2), [1,2];

$enum->data([1 .. 10]);
my $sliced = [[1,2,3],[4,5,6],[7,8,9],[10]];
my $data = [];
my $size = $enum->each_slice(3, sub { my ($slice) = @_; push @$data, $slice; });
is_deeply $data, $sliced;
is $size, 4;
is_deeply $enum->slice(3), $sliced;

$enum->data([{num=>1},{num=>2},{num=>3}]);
is_deeply $enum->pluck('num'), $enum->map(sub { $_->{num} });

done_testing;

