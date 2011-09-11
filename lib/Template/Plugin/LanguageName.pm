package Template::Plugin::LanguageName;
use strict;
use warnings;
use parent qw(Template::Plugin::Filter);
use Locale::Codes::Language;

my $FILTER_NAME = 'language_name';

sub init {
    my $self = $_[0];
    $self->install_filter($FILTER_NAME);
    $self;
}

sub filter {
    my $code = $_[1];
    code2language($code, length($code) == 3 ? LOCALE_LANG_ALPHA_3 : LOCALE_LANG_ALPHA_2) || $code;
}

1;
