package Dancer::Plugin::Locale::TextDomain;
use strict;
use warnings;
use Dancer::Plugin;
use Dancer qw(:syntax);
use Carp qw(confess);
use Locale::TextDomain ();

our $VERSION = '0.1';

my $default_textdomain = plugin_setting->{textdomain} || 'messages';
my $default_locale = plugin_setting->{locale} || 'en_US';
my $locale_path = plugin_setting->{locale_path} || 'locale';

my %pkgs;

sub textdomain {
    my $textdomain = setting('textdomain') || $default_textdomain;

    $pkgs{$textdomain} ||= do {
        my $pkg = "Dancer::Plugin::Locale::TextDomain::__DOMAINS__::" . keys %pkgs;
        my $dir = 
        eval join "\n",
            "package $pkg;",
            "use Locale::TextDomain '$textdomain', '$locale_path';",
            'sub td__    { my ($pkg, $msgid) = @_; __($msgid) }',
            'sub td__x   { my ($pkg, $msgid, %vars) = @_; __x($msgid, %vars) }',
            'sub td__n   { my ($pkg, $msgid, $msgid_plural, $count) = @_; __n($msgid, $msgid_plural, $count) }',
            'sub td__nx  { my ($pkg, $msgid, $msgid_plural, $count, %vars) = @_; __nx($msgid, $msgid_plural, $count, %vars) }',
            'sub td__p   { my ($pkg, $msgctx, $msgid); __p($msgctx, $msgid) }',
            'sub td__px  { my ($pkg, $msgctx, $msgid, %vars); __px($msgctx, $msgid, %vars) }',
            'sub td__np  { my ($pkg, $msgctx, $msgid, $msgid_plural, $count) = @_; __np($msgctx, $msgid, $msgid_plural, $count) }',
            'sub td__npx { my ($pkg, $msgctx, $msgid, $msgid_plural, $count, %vars) = @_; __npx($msgctx, $msgid, $msgid_plural, $count, %vars) }',
            '1;'
            or confess($@);
        $pkg;
    };
}

sub td__    { textdomain->td__(@_) }
sub td__x   { textdomain->td__x(@_) }
sub td__n   { textdomain->td__n(@_) }
sub td__nx  { textdomain->td__nx(@_) }
sub td__p   { textdomain->td__p(@_) }
sub td__pn  { textdomain->td__pn(@_) }
sub td__pnx { textdomain->td__pnx(@_) }

# TODO TT arg fix
# substr($which, -1) eq 'x' && ref($_[-1]) eq 'HASH' && push(@_, %{pop(@_)});
before_template sub {
    my $vars = $_[0];
    $Template::Stash::PRIVATE = undef;
    $vars->{__}    = \&td__;
    $vars->{__x}   = \&td__x;
    $vars->{__n}   = \&td__n;
    $vars->{__nx}  = \&td__nx;
    $vars->{__p}   = \&td__p;
    $vars->{__pn}  = \&td__pn;
    $vars->{__pnx} = \&td__pnx;
};

register __    => \&td__;
register __x   => \&td__x;
register __n   => \&td__n;
register __nx  => \&td__nx;
register __p   => \&td__p;
register __pn  => \&td__pn;
register __pnx => \&td__pnx;

register_plugin;

1;
