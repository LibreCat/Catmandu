package Catmandu::Paged;

use namespace::clean;
use Catmandu::Sane;
use Moo::Role;

requires 'start';
requires 'limit';
requires 'total';

# has max_pages_in_spread => (is => 'rw', lazy => 1, default => sub { 5 });

# has _pager => (
#     is => 'ro',
#     init_arg => undef,
#     lazy => 1,
#     builder => '_build_pager',
#     handles => {
#         page => 'current_page',
#         first_page => 'first_page',
#         last_page => 'last_page',
#         next_page => 'next_page',
#         previous_page => 'previous_page',
#         first_on_page => 'first',
#         last_on_page => 'last',
#         pages_in_spread => 'pages_in_spread',
#         page_ranges => 'page_ranges',
#     },
# );

sub first_page {
    my $self = shift;

    return 1;
}

sub last_page {
    my $self = shift;

    my $pages = $self->total / $self->limit;
    my $last_page;

    ( $pages == int $pages ) ? ( $last_page = $pages )
        : ( $last_page = 1 + int($pages) );

    $last_page = 1 if $last_page < 1;

    return $last_page;
}

sub current_page {
    my $self = shift;

    #( $self->start <= $self->limit ) && ( return $self->first_page );
    #( $self->start > ($self->total - $self->limit) ) && ( return $self->last_page );
    my $current = 1 + int ($self->start/$self->limit);
}

sub previous_page {
    my $self = shift;

    ( $self->current_page > 1 ) ?  ( return $self->current_page - 1 )
        : ( return undef );
}

sub next_page {
    my $self = shift;

    ( $self->current_page < $self->last_page ) ?  ( return $self->current_page + 1 )
        :  ( return undef );
}

sub first_on_page {
    my $self = shift;

    ( $self->total == 0 ) ? ( return 0 )
        : (return ( ( $self->current_page - 1 ) * $self->limit ) + 1 );
}

sub last {
    my $self = shift;

    ( $self->current_page == $self->last_page ) ? ( return $self->total_entries )
        : ( return ( $self->current_page * $self->limit ) );
}

sub page_size {
    goto &limit;
}

1;
