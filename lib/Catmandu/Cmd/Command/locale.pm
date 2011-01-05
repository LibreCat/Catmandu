package Catmandu::Cmd::Command::locale;
# VERSION
use namespace::autoclean;
use Moose;
use Path::Class;
use File::Path qw(make_path);
use File::Spec;
use File::Copy;
use PPI;

extends qw(Catmandu::Cmd::Command);

has domains => (
    traits => ['NoGetopt', 'Hash'],
    is => 'ro',
    isa => 'HashRef[ArrayRef]',
    default => sub { {} },
    handles => {
        domain_names => 'keys',
    },
);

sub execute {
    my ($self, $opts, $args) = @_;

    if (my $lib = Catmandu->path('lib')) {
        my $statement_finder = sub {
            my $node = $_[1];
            $node->isa('PPI::Statement::Include') &&
            $node->type eq 'use' &&
            $node->module eq 'Locale::TextDomain';
        };

        dir($lib)->recurse(callback => sub {
            my $file = shift;
            my $path = $file->stringify;

            return unless -f $path && $path =~ /\.pm$/;

            my $doc = PPI::Document->new($path);
            my $statement = $doc->find_first($statement_finder);
            if ($statement) {
                my @args = $statement->arguments;
                my $node = $args[0];
                my $domain;
                if ($node->isa('PPI::Token::Quote')) {
                    $domain = $node->string;
                } elsif ($node->isa('PPI::Token::QuoteLike::Words')) {
                    ($domain) = $node->literal;
                }

                my $paths = $self->domains->{$domain} ||= [];
                push @$paths, $path;
            }
        });
    }

    if (my $template = Catmandu->path('template')) {
        dir($template)->recurse(callback => sub {
            my $file = shift;
            my $path = $file->stringify;

            return unless -f $path;

            my $extract = 0;
            my $domain = 'messages';

            my $fh = $file->openr;
            while (defined(my $line = $fh->getline)) {
                if ($line =~ /(?:use|USE)\s+Catmandu\.Locale/) {
                    $extract = 1;
                    if ((my $d) = $line =~ /(?:use|USE)\s+Catmandu\.Locale\([\'\"](\w+)[\'\"]\)/) {
                        $domain = $d;
                    }
                    last;
                }
            }
            $fh->close;

            if ($extract) {
                my $paths = $self->domains->{$domain} ||= [];
                push @$paths, $path;
            }

        });
    }

    my $po_dir = File::Spec->catfile(Catmandu->home, 'po');
    my $loc_data_dir = File::Spec->catfile(Catmandu->home, 'lib', 'LocaleData');

    # pot
    for my $domain ($self->domain_names) {
        my $domain_files = $self->domains->{$domain};
        make_path(File::Spec->catfile($po_dir, $domain));
        my $fh = file($po_dir, "$domain.files")->openw;
        $fh->print("$_\n") for @$domain_files;
        $fh->close;
        system(join(" ",
            "xgettext --output=$po_dir/$domain.pot --from-code=utf-8 --language=perl",
            "--files-from=$po_dir/$domain.files",
            "--keyword --keyword='\$\$__' --keyword=__ --keyword=__x",
            "--keyword=__n:1,2 --keyword=__nx:1,2 --keyword=__xn:1,2",
            "--keyword=__p:1c,2 --keyword=__np:1c,2,3",
            "--keyword=__npx:1c,2,3 --keyword=N__ --keyword=N__n:1,2",
            "--keyword=N__p:1c,2 --keyword=N__np:1c,2,3 --keyword=%__"
        )) == 0 or die "Can't write $domain.pot";
    }
    # update po
    for my $domain ($self->domain_names) {
        for my $po (dir($po_dir, $domain)->children(no_hidden => 1)) {
            my $path = $po->stringify;
            next if $path !~ /\.po$/;
            system("msgmerge --verbose -o $path $path $po_dir/$domain.pot") == 0 or die "Can't update $po";
        }
    }
    # compile mo
    for my $domain ($self->domain_names) {
        for my $po (dir($po_dir, $domain)->children(no_hidden => 1)) {
            my $path = $po->stringify;
            next if $path !~ /\.po$/;
            my $mo = $path;
            $mo =~ s/\.po$/\.mo/;
            system("msgfmt --check --statistics --verbose -o $mo $path") == 0 or die "Can't compile $mo";
        }
    }
    # install mo
    for my $domain ($self->domain_names) {
        for my $mo (dir($po_dir, $domain)->children(no_hidden => 1)) {
            my $path = $mo->stringify;
            next if $path !~ /\.mo$/;
            my $locale = $mo->basename;
            $locale =~ s/\.mo$//;
            my $dest_dir = File::Spec->catfile($loc_data_dir, $locale, 'LC_MESSAGES');
            make_path($dest_dir);
            copy($path, File::Spec->catfile($dest_dir, "$domain.mo")) or die "Copy failed: $!";
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Catmandu::Cmd::Command::locale - generate localization catalogs

