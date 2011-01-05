package Catmandu::Guides::Localization;
# ABSTRACT: Localizing a Catmandu app
# VERSION

=head1 IN YOUR APP

    package Example::App;

    use Catmandu::App;
    use Locale::TextDomain 'example';

    get '/foo' => sub {
        my $self = shift;
        $self->print(__"Hello");
    }

=head1 IN YOUR TEMPLATES

    [% USE Catmandu.Locale('example') %]

    <h1>[% __("Hello") %]</h1>

