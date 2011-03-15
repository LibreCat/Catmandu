package Catmandu::App::Plugin::Locale;
use Catmandu::Sane;
use Locale::TextDomain ();
use Locale::Util ();

sub import_plugin {
    my ($plugin, $app, $opts) = @_;

    my $param = $opts->{param};
    my $textdomain = $opts->{textdomain} || "messages";

    eval "package $app; use Locale::TextDomain '$textdomain'; 1" or confess $@;

    # detect locale
    $app->before(run => sub {
        my $self = $_[0];

        my @locale = Locale::Util::parse_http_accept_language($self->env->{HTTP_ACCEPT_LANGUAGE});

        if ($param) {
            if (my $loc = $self->param($param) || $self->request->param($param)) {
                unshift @locale, $loc;
            }
        }

        Locale::Util::web_set_locale(\@locale);
    });
}

1;
