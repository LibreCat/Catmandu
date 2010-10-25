package Catmandu;

use 5.010;
use Carp qw(confess);
use Try::Tiny;
use Hash::Merge ();
use Path::Class;
use Template;
use YAML ();
use JSON ();

sub home {
    $ENV{CATMANDU_HOME} or confess "CATMANDU_HOME not set";
}

sub env {
    $ENV{CATMANDU_ENV} or confess "CATMANDU_ENV not set";
}

sub stack {
    state $stack //= do {
        my $pkg = $_[0];
        my $yml = file($pkg->home, "catmandu.yml")->stringify;
        if (-f $yml) {
            try {
                YAML::LoadFile($file);
            } catch {
                confess "Can't load catmandu.yml";
            };
        } else {
            [ $pkg->home ];
        }
    };
}

sub paths {
    my ($pkg, $dir) = @_;
    if ($dir) {
        [ grep { -d $_ } map { dir($pkg->home, $_, $dir)->stringify } @{$pkg->stack} ];
    } else {
        [ map { dir($pkg->home, $_)->stringify } @{$pkg->stack} ];
    }
}

sub lib {
   @{$_[0]->paths('lib')};
}

sub find_psgi {
    my ($pkg, $file) = @_;
    $file = "$file.psgi" if $file !~ /\.psgi$/;
    my $paths = $pkg->paths('psgi');
    my @files = grep { -f $_ } map { file($_, $file)->stringify } @$paths;
    $files[0];
}

sub conf {
    state $conf //= do {
        my $pkg = shift;
        my $merger = Hash::Merge->new('RIGHT_PRECEDENT');
        my $merged = {};

        foreach my $conf_path ( reverse @{$pkg->paths('conf')} ) {
            dir($conf_path)->recurse(depthfirst => 1, callback => sub {
                my $file = shift;
                my $path = $file->stringify;
                my $hash;
                -f $path or return;
                given ($path) {
                    when (/\.json$/) { $hash = JSON::decode_json($file->slurp) }
                    when (/\.yml$/)  { $hash = YAML::LoadFile($path) }
                    when (/\.pl$/)   { $hash = do $path }
                }
                if (ref $hash eq 'HASH') {
                    $merge = $merger->merge($merged, $hash);
                }
            });
        }

        if (my $hash = delete $merged->{env} and $hash = delete $hash->{$pkg->env}) {
            $merged = $merger->merge($merged, $hash);
        }

        $merged;
    };
}

sub print_template {
    my $pkg = shift;
    state $template //= Template->new({
        INCLUDE_PATH => $pkg->paths('template'),
    });
    $template->process(@_)
        or confess $template->error;
}

__PACKAGE__;

