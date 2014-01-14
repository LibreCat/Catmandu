package Catmandu::Paged;

use namespace::clean;
use Catmandu::Sane;
use Moo::Role;

requires 'start';
requires 'limit';
requires 'total';

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
