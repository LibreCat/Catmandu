package Template::Plugin::UTF8;
use parent qw(Template::Plugin::Filter);
use Encode;

my $FILTER_NAME = 'utf8';

sub init {
    my ($self) = @_;

    $self->install_filter($FILTER_NAME);

    $self;
}

sub filter {
    my ($self, $text) = @_;

    Encode::encode_utf8($text);
}

1;
