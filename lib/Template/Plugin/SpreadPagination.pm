package Template::Plugin::SpreadPagination;
use strict;
use warnings;
use parent qw(Template::Plugin);
use Data::SpreadPagination;

sub new {
    my ($class, $context, $args) = @_;
    Data::SpreadPagination->new($args);
}

1;

=head1 NAME

Template::Plugin::SpreadPagination - Template spread pagination plugin

=head1 SYNOPSIS

    [% USE pager = SpreadPagination(totalEntries=total,entriesPerPage=limit,startEntry=start+1, maxPages=8) %]

    [%- IF pager.previous_page %]
    <a class="page prev" href="...">previous</a>
    [%- END %]

    [%- FOREACH page IN pager.pages_in_spread %]
    [%- IF page == pager.current_page %]
    <span class="page current">[% page %]</span>
    [%- ELSIF page.defined %]
    <span class="page"><a href="...">[% page %]</a></span>
    [%- ELSE %]
    ...
    [%- END %]

=head1 SEE ALSO

L<Data::Spreadpagination>.

=cut
