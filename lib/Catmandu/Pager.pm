package Catmandu::Pager;

use Catmandu::Sane;
use Data::Pageset;
use Moo::Role;

requires 'start';
requires 'limit';
requires 'total';

has _pager => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_pager',
    handles => {
        first_page => 'first_page',
        last_page => 'last_page',
        next_page => 'next_page',
        previous_page => 'previous_page',
        pages_per_set => 'pages_per_set',
        pages_in_set => 'pages_in_set',
        next_page_set => 'next_set',
        previous_page_set => 'previous_set',
        first_on_page => 'first',
        last_on_page => 'last',
        size => 'entries_on_this_page',
    },
);

sub _build_pager {
    my $self = $_[0];
    Data::Pageset->new({
        total_entries => $self->total,
        entries_per_page => $self->limit,
        current_page => $self->page,
        pages_per_set => 5,
        mode => 'slide',
    });
}

sub page {
    $_[0]->{page} ||= int($_[0]->start / $_[0]->limit) + 1;
}

sub on_page {
    [$_[0]->first_on_page .. $_[0]->last_on_page];
}

1;
