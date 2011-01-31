package Catmandu::App::Traits::Locale;
# VERSION
use Moose::Role;
use Locale::Util ();

has locale_param => (is => 'rw', isa => 'Str');

before run => sub {
    my ($self, $sub) = @_;

    my @locales = Locale::Util::parse_http_accept_language($self->env->{HTTP_ACCEPT_LANGUAGE});

    if (my $key = $self->locale_param) {
        if (my $loc = $self->param($key) || $self->req->param($key)) {
            unshift @locales, $loc;
        }
    }

    Locale::Util::web_set_locale(\@locales);
};

no Moose::Role;

1;

