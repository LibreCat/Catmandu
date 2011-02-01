package Catmandu::Guides::Localization;
# ABSTRACT: Localizing a Catmandu app
# VERSION

=head1 IN YOUR APP

    package Example::App;

    use base 'Catmandu::App';
    use Locale::TextDomain 'example';

    sub hello :GET {
        my $self = shift;
        $self->print(__"Hello");
    }

=head1 IN YOUR TEMPLATES

    [% USE Catmandu.Locale('example') %]

    <h1>[% __("Hello") %]</h1>

