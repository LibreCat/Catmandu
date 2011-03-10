package Template::Plugin::Catmandu::Locale;
use Catmandu::Sane;
use Catmandu::Util;
use Locale::TextDomain ();
use parent 'Template::Plugin';

{
    my $domain_pkgs = {};

    sub new {
        my ($class, $context, $domain) = @_;

        $domain ||= "messages";

        my $domain_pkg = $domain_pkgs->{$domain} ||= do {
            my $pkg = Catmandu::Util::create_package;
            eval join "\n",
                "package $pkg;",
                "use Locale::TextDomain '$domain';",
                'sub ___ { __(@_) }',
                'sub ___x { __x(@_) }',
                'sub ___n { __n(@_) }',
                'sub ___nx { __nx(@_) }',
                'sub ___p { __p(@_) }',
                'sub ___px { __px(@_) }',
                'sub ___np { __np(@_) }',
                'sub ___npx { __npx(@_) }'
                or $context->throw($@);
            $pkg;
        };

        {
            no strict 'refs';
            $context->stash->update({
                __    => \&{"${domain_pkg}::___"},
                __x   => \&{"${domain_pkg}::___x"},
                __n   => \&{"${domain_pkg}::___n"},
                __nx  => \&{"${domain_pkg}::___nx"},
                __xn  => \&{"${domain_pkg}::___nx"},
                __p   => \&{"${domain_pkg}::___p"},
                __px  => \&{"${domain_pkg}::___px"},
                __np  => \&{"${domain_pkg}::___np"},
                __npx => \&{"${domain_pkg}::___npx"},
                N__   => \&{"${domain_pkg}::N__"},
                N__n  => \&{"${domain_pkg}::N__n"},
                N__p  => \&{"${domain_pkg}::N__p"},
                N__np => \&{"${domain_pkg}::N__np"},
            });
        };

        bless {
            textdomain => $domain,
        }, $class;
    }
};

sub textdomain {
    $_[0]->{textdomain};
}

1;
