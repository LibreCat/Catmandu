package Template::Plugin::Content;

use strict;
use warnings;
use parent qw(Template::Plugin::Filter);
use Dancer qw(:syntax vars);

my $FILTER_NAME = 'content_for';

sub init {
    my $self = $_[0];
    $self->{_DYNAMIC} = 1;
    $self->install_filter($FILTER_NAME);
    $self;
}

sub filter {
    my ($self, $text, $args) = @_;
    for my $key (@$args) {
        my $content = vars->{_content_for}{$key};
        vars->{_content_for}{$key} = $content ? "$content$text" : $text;
    }
    "";
}

sub for {
    my ($self, $key) = @_;
    vars->{_content_for}{$key} || "";
}

1;
