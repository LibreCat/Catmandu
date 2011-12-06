package Template::Plugin::Content;

use strict;
use warnings;
use parent qw(Template::Plugin);

sub new {
    my ($class, $context) = @_;

    my $self = bless {
        stash => $context->stash,
    }, $class;

    $context->define_filter('content_for', sub {
        my ($filter_context, $key) = @_;
        return sub {
            $self->add($key, @_);
        };
    }, 1);

    $self;
}

sub add {
    my ($self, $key, @more) = @_;
    $key = "content_for_$key";
    my $stash = $self->{stash};
    my $content = $stash->get($key) || "";
    $content .= join("", @more);
    $stash->set($key, $content);
    "";
}

sub for {
    my ($self, $key) = @_;
    $self->{stash}->get("content_for_$key");
}

1;
