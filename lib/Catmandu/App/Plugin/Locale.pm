package Catmandu::App::Plugin::Locale;
use Locale::TextDomain ();
use Locale::Util ();

my @EXPORT_PLUGIN = qw(
    locale_textdomain
    locale_param
);

sub locale_textdomain {}

sub locale_param {}

sub import_plugin {
    my ($plugin, $app) = @_;

    my $domain = $app->locale_textdomain || "messages";

    eval "package $app; use Locale::TextDomain '$domain'; 1" or confess $@;

    # detect locale
    $app->before(run => sub {
        my $self = $_[0];

        my @locales = Locale::Util::parse_http_accept_language($self->env->{HTTP_ACCEPT_LANGUAGE});

        if (my $key = $self->locale_param) {
            if (my $loc = $self->param($key) || $self->request->param($key)) {
                unshift @locales, $loc;
            }
        }

        Locale::Util::web_set_locale(\@locales);
    });
}

1;
