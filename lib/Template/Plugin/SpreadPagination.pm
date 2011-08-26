package Template::Plugin::SpreadPagination;
use parent qw(Template::Plugin);
use Data::SpreadPagination;

sub new {
    my ($class, $context, $args) = @_;
    Data::SpreadPagination->new($args);
}

1;
