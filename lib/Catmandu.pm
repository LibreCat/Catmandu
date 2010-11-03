package Catmandu;

use 5.010;
use Carp qw(confess);
use Hash::Merge ();
use Path::Class;
use Template;
use YAML ();
use JSON ();

sub instance {
    state $instance //= $_[0]->new;
}

sub new {
    my $class = ref $_[0] ? ref $_[0] : $_[0];
    bless {}, $class;
}

sub home {
    $ENV{CATMANDU_HOME} or confess "CATMANDU_HOME not set";
}

sub env {
    $ENV{CATMANDU_ENV} or confess "CATMANDU_ENV not set";
}

sub catmandu_lib {
    state $catmandu_lib //=
        file(__FILE__)->dir->parent->subdir('lib')->absolute->resolve->stringify;
}

sub stack {
    my $self = shift;
    unless (ref $self) {
        return $self->instance->stack;
    }
    $self->{stack} //= do {
        my $file = file($self->home, "catmandu.yml")->stringify;
        if (-f $file) {
            YAML::LoadFile($file);
        } else {
            [];
        }
    };
}

sub paths {
    my ($self, $dir) = @_;
    my $stack = $self->stack;
    my $paths = [ $self->home, map { dir($self->home, $_)->stringify } @$stack ];
    if ($dir) {
        [ grep { -d $_ } map { dir($_, $dir)->stringify } @$paths ];
    } else {
        $paths;
    }
}

sub path_list {
   @{$_[0]->paths($_[1])};
}

sub lib {
   @{$_[0]->paths('lib')};
}

sub find_psgi {
    my ($self, $file) = @_;
    $file = "$file.psgi" if $file !~ /\.psgi$/;
    my $paths = $self->paths('psgi');
    my @files = grep { -f $_ } map { file($_, $file)->stringify } @$paths;
    $files[0];
}

sub conf {
    my $self = shift;
    unless (ref $self) {
        return $self->instance->conf;
    }
    $self->{conf} //= do {
        my $merger = Hash::Merge->new('RIGHT_PRECEDENT');
        my $merged = {};

        foreach my $conf_path ( reverse @{$self->paths('conf')} ) {
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

        # load environment specific conf
        if (my $hash = delete $merged->{env} and $hash = delete $hash->{$self->env}) {
            $merged = $merger->merge($merged, $hash);
        }

        $merged;
    };
}

sub print_template {
    my $self = shift;
    unless (ref $self) {
        return $self->instance->print_template(@_);
    }
    my $template = $self->{template} //= Template->new({
        PLUGIN_BASE  => 'Catmandu::Template::Plugin',
        INCLUDE_PATH => $self->paths('template'),
    });
    $template->process(@_)
        or confess $template->error;
}

__PACKAGE__;

