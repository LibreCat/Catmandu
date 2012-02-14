package Catmandu::Pager;

use Catmandu::Sane;
use Data::SpreadPagination;
use Moo::Role;

requires 'start';
requires 'limit';
requires 'total';

has max_pages_in_spread => (is => 'rw', default => sub { 5 });

has _pager => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_pager',
    handles => {
        page => 'current_page',
        first_page => 'first_page',
        last_page => 'last_page',
        next_page => 'next_page',
        previous_page => 'previous_page',
        first_on_page => 'first',
        last_on_page => 'last',
        pages_in_spread => 'pages_in_spread',
        page_ranges => 'page_ranges',
    },
);

sub _build_pager {
    my $self = $_[0];
    Data::SpreadPagination->new({
        totalEntries   => $self->total,
        entriesPerPage => $self->limit,
        startEntry     => $self->start+1,
        maxPages       => $self->max_pages_in_spread,
    });
}

sub page_size {
    goto &limit;
}

1;
