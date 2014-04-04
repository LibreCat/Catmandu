package Catmandu::Paged;

use namespace::clean;
use Catmandu::Sane;
use Moo::Role;

requires 'start';
requires 'limit';
requires 'total';

has max_pages_in_spread => ( is => 'rw', lazy => 1, default => sub {5} );

# function _do_pagination copied from Data::SpreadPagination,
# decrease dependencies for Catmandu

sub _ceil {
    my $x = shift;
    return int( $x + 0.9999999 );
}

sub _floor {
    my $x = shift;
    return int $x;
}

sub _round {
    my $x = shift;
    return int( $x + 0.5 );
}

sub _do_pagination {
    my $self             = shift;
    my $total_entries    = $self->total;
    my $entries_per_page = $self->limit;
    my $current_page     = $self->page;
    my $max_pages        = $self->max_pages_in_spread;

    # qNsizes
    my @q_size = ();
    my ( $add_pages, $adj );

    # step 2
    my $total_pages = _ceil( $total_entries / $entries_per_page );
    my $visible_pages
        = $max_pages < ( $total_pages - 1 )
        ? $max_pages
        : $total_pages - 1;
    if ( $total_pages - 1 <= $max_pages ) {
        @q_size = ( $current_page - 1, 0, 0, $total_pages - $current_page );
    }
    else {
        @q_size = (
            _floor( $visible_pages / 4 ),
            _round( $visible_pages / 4 ),
            _ceil( $visible_pages / 4 ),
            _round( ( $visible_pages - _round( $visible_pages / 4 ) ) / 3 )
        );
        if ( $current_page - $q_size[0] < 1 ) {
            $add_pages = $q_size[0] + $q_size[1] - $current_page + 1;
            @q_size    = (
                $current_page - 1,
                0,
                $q_size[2] + _ceil( $add_pages / 2 ),
                $q_size[3] + _floor( $add_pages / 2 )
            );
        }
        elsif ( $current_page - $q_size[1] - _ceil( $q_size[1] / 3 )
            <= $q_size[0] )
        {
            $adj = _ceil( ( 3 * ( $current_page - $q_size[0] - 1 ) ) / 4 );
            $add_pages = $q_size[1] - $adj;
            @q_size    = (
                $q_size[0], $adj,
                $q_size[2] + _ceil( $add_pages / 2 ),
                $q_size[3] + _floor( $add_pages / 2 )
            );
        }
        elsif ( $current_page + $q_size[3] >= $total_pages ) {
            $add_pages
                = $q_size[2] + $q_size[3] - $total_pages + $current_page;
            @q_size = (
                $q_size[0] + _floor( $add_pages / 2 ),
                $q_size[1] + _ceil( $add_pages / 2 ),
                0, $total_pages - $current_page
            );
        }
        elsif ( $current_page + $q_size[2] >= $total_pages - $q_size[3] ) {
            $adj = _ceil(
                ( 3 * ( $total_pages - $current_page - $q_size[3] ) ) / 4 );
            $add_pages = $q_size[2] - $adj;
            @q_size    = (
                $q_size[0] + _floor( $add_pages / 2 ),
                $q_size[1] + _ceil( $add_pages / 2 ),
                $adj, $q_size[3]
            );
        }
    }

    # step 3 (PROFIT)
    $self->{PAGE_RANGES} = [
        $q_size[0] == 0 ? undef
        : [ 1, $q_size[0] ],
        $q_size[1] == 0 ? undef
        : [ $current_page - $q_size[1], $current_page - 1 ],
        $q_size[2] == 0 ? undef
        : [ $current_page + 1, $current_page + $q_size[2] ],
        $q_size[3] == 0 ? undef
        : [ $total_pages - $q_size[3] + 1, $total_pages ],
    ];

}

sub first_page {
    return 1;
}

sub last_page {
    my $self = shift;

    my $last = $self->total / $self->limit;
    return _ceil($last);
}

sub page {
    my $self = shift;

    ( $self->start == 0 ) && ( return 1 );

    my $page = _ceil( ( $self->start + 1 ) / $self->limit );
    ( $page < $self->last_page )
        ? ( return $page )
        : ( return $self->last_page );
}

sub previous_page {
    my $self = shift;

    ( $self->page > 1 )
        ? ( return $self->page - 1 )
        : ( return undef );
}

sub next_page {
    my $self = shift;

    ( $self->page < $self->last_page )
        ? ( return $self->page + 1 )
        : ( return undef );
}

sub first_on_page {
    my $self = shift;

    ( $self->total == 0 )
        ? ( return 0 )
        : ( return ( ( $self->page - 1 ) * $self->limit ) + 1 );
}

sub last {
    my $self = shift;

    ( $self->page == $self->last_page )
        ? ( return $self->total_entries )
        : ( return ( $self->page * $self->limit ) );
}

sub page_size {
    my $self = shift,;
    return $self->limit;
}

sub page_ranges {
    my $self = shift;

    return @{ $self->{PAGE_RANGES} };
}

sub pages_in_spread {
    my $self = shift;

    $self->_do_pagination;
    my $ranges = $self->{PAGE_RANGES};
    my $pages  = [];

    if ( !defined $ranges->[0] ) {
        push @$pages, undef if $self->page > 1;
    }
    else {
        push @$pages, $ranges->[0][0] .. $ranges->[0][1];
        push @$pages, undef
            if defined $ranges->[1]
            and ( $ranges->[1][0] - $ranges->[0][1] ) > 1;
    }

    push @$pages, $ranges->[1][0] .. $ranges->[1][1] if defined $ranges->[1];
    push @$pages, $self->page;
    push @$pages, $ranges->[2][0] .. $ranges->[2][1] if defined $ranges->[2];

    if ( !defined $ranges->[3] ) {
        push @$pages, undef if $self->page < $self->last_page;
    }
    else {
        push @$pages, undef
            if defined $ranges->[2]
            and ( $ranges->[3][0] - $ranges->[2][1] ) > 1;
        push @$pages, $ranges->[3][0] .. $ranges->[3][1];
    }

    return $pages;
}

1;
