package Catmandu::App::Plugin::Locale;
# ABSTRACT: Catmandu::App Plugin to detect the desired locale
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

=head1 DESCRIPTION

This plugin will try to set the desired locale by looking at the
value of C<locale_param> or the value of the C<Accept-Language>
HTTP header.

=head1 ATTRIBUTES

=head2 locale_param([$key])

Get or set the param used to detect the desired locale.
The plugin will look for this param in the app params and the
params of the current request.

    my $app = Catmandu::App->with_traits('Locale')->new;
    $app->locale_param('lang');

=head1 SEE ALSO

L<Locale::Util>

