package Template::Plugin::Catmandu::UTF8;

my $FILTER_NAME = 'utf8';

use Encode;
use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

sub init {
    my $self = shift;

    $self->install_filter($FILTER_NAME);

    return $self;
}

sub filter {
    my ($self, $text) = @_;

    return Encode::encode_utf8($text);
}

1;

