package Template::Plugin::UTF8;
use parent qw(Template::Plugin::Filter);
use Encode;

my $FILTER_NAME = 'utf8';

sub init {
    my $self = $_[0];
    $self->install_filter($FILTER_NAME);
    $self;
}

sub filter {
    Encode::encode_utf8 $_[1];
}

1;
