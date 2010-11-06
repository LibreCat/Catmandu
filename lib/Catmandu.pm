package Catmandu;

use 5.010;
use Hash::Merge ();
use Path::Class;
use Template;
use YAML ();
use JSON ();
use Any::Moose;

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

sub instance {
    state $instance //= do {
        my $class = ref $_[0] ? ref $_[0] : $_[0];
        $class->new;
    };
}

has _stack    => (is => 'ro', init_arg => undef, lazy => 1, builder => '_build_stack');
has _conf     => (is => 'ro', init_arg => undef, lazy => 1, builder => '_build_conf');
has _template => (is => 'ro', init_arg => undef, lazy => 1, builder => '_build_template');

sub _build_stack {
    my $self = shift;
    my $file = file($self->home, "catmandu.yml")->stringify;
    if (-f $file) {
        YAML::LoadFile($file);
    } else {
        [];
    }
}

sub _build_conf {
    my $self = shift;
    my $merger = Hash::Merge->new('RIGHT_PRECEDENT');
    my $conf = {};

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
                $conf = $merger->merge($conf, $hash);
            }
        });
    }

    # load env specific conf
    if (my $hash = delete $conf->{$self->env}) {
        $conf = $merger->merge($conf, $hash);
    }

    $conf;
}

sub _build_template {
    my $self = shift;
    my $args = $self->conf->{template}{args} || {};
    Template->new({
        PLUGIN_BASE  => 'Catmandu::Template::Plugin',
        INCLUDE_PATH => $self->paths('template'),
        VARIABLES    => {
            catmandu => $self,
        },
        %$args,
    });
}

sub stack {
    my $self = ref $_[0] ? $_[0] : $_[0]->instance; $self->_stack;
}

sub conf {
    my $self = ref $_[0] ? $_[0] : $_[0]->instance; $self->_conf;
}

sub print_template {
    my $self = ref $_[0] ? shift : shift->instance;
    my $tmpl = $self->_template;
    my $file = shift;
    $file = "$file.tt" if $file !~ /\.tt$/;
    $tmpl->process($file, @_)
        or confess $tmpl->error;
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

__PACKAGE__->meta->make_immutable;
no Any::Moose;
__PACKAGE__;

