package Template::Plugin::Catmandu::Locale;
# ABSTRACT: Locale::TextDomain for TT
# VERSION
use 5.010;
use strict;
use warnings;
use base 'Template::Plugin';

$Template::Stash::PRIVATE = 0;

my $domain_pkgs = {};

sub new {
    my ($class, $context, $domain) = @_;

    $domain ||= "messages";

    my $pkg = $domain_pkgs->{$domain} ||= do {
        my $ns = "${class}::${domain}";
        eval join ';',
            "package $ns",
            "use Locale::TextDomain '$domain'",
            'sub ___ { my ($msg) = @_; __($msg) }',
            'sub ___x { my ($msg, @var) = @_; __x($msg, @var) }',
            'sub ___n { my ($msg, $plural_msg, $n) = @_; __n($msg, $plural_msg, $n) }',
            'sub ___nx { my ($msg, $plural_msg, $n, @var) = @_; __nx($msg, $plural_msg, $n, @var) }',
            'sub ___p { my ($msg_ctx, $msg) = @_; __p($msg_ctx, $msg) }',
            'sub ___px { my ($msg_ctx, $msg, @var) = @_; __px($msg_ctx, $msg, @var) }',
            'sub ___np { my ($msg_ctx, $msg, $plural_msg, $n) = @_; __np($msg_ctx, $msg, $plural_msg, $n) }',
            'sub ___npx { my ($msg_ctx, $msg, $plural_msg, $n, @var) = @_; __npx($msg_ctx, $msg, $plural_msg, $n, @var) }';
        if ($@) {
            $context->throw($@);
        }
        $ns;
    };

    $context->stash->update({
        __ => \&{"${pkg}::___"},
        __x => \&{"${pkg}::___x"},
        __n => \&{"${pkg}::___n"},
        __nx => \&{"${pkg}::___nx"},
        __xn => \&{"${pkg}::___nx"},
        __p => \&{"${pkg}::___p"},
        __px => \&{"${pkg}::___px"},
        __np => \&{"${pkg}::___np"},
        __npx => \&{"${pkg}::___npx"},
        N__ => \&{"${pkg}::N__"},
        N__n => \&{"${pkg}::N__n"},
        N__p => \&{"${pkg}::N__p"},
        N__np => \&{"${pkg}::N__np"},
    });

    bless {
        domain => $domain,
    }, $class;
}

1;

