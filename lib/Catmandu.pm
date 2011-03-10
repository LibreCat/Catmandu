package Catmandu;
use Catmandu::Sane;
use List::Util qw(first);
use Cwd qw(getcwd realpath);
use File::Spec::Functions qw(catfile catdir file_name_is_absolute);
use File::Basename qw(basename);
use File::Find;
use File::Slurp qw(slurp);
use JSON ();
use YAML ();
use Template;

our $VERSION = '0.01';

my $home;
my $env;
my $stash;
my $paths;
my $renderer;

sub default_home {
    getcwd;
}

sub default_env {
    'development';
}

sub init {
    my $self = shift;
    my $args = ref $_[0] eq 'HASH' ? $_[0] : {@_};

    if ($home || $env) {
        confess "Already initialized";
    }

    $home = $args->{home} ? realpath($args->{home}) : $self->default_home;
    $env  = $args->{env}  ? $args->{env}            : $self->default_env;
}

sub load_libs {
    unshift @INC, $_[0]->path_list('lib');
}

sub auto {
    find sub { do $_ if -f and /^\w+\.pl$/ }, reverse $_[0]->path_list('auto') || return;
}

sub home {
    $home ||= $_[0]->default_home;
}

sub env {
    $env ||= $_[0]->default_env;
}

sub stash {
    $stash ||= {};
}

sub paths {
    my ($self, @dir) = @_;

    $paths || do {
        $paths = [$self->home];
        if (my $stack = $self->load_conf_file($self->home, 'catmandu')) {
            push @$paths, map {
                file_name_is_absolute($_) ? realpath($_) : catdir($self->home, $_);
            } @$stack;
        }
    };

    if (@dir) {
        [ grep { -d } map { catdir($_, @dir) } @$paths ];
    } else {
        [ @$paths ];
    }
}

sub path_list {
    my ($self, @dir) = @_; @{$self->paths(@dir)};
}

sub path {
    my ($self, @dir) = @_;

    if (@dir) {
        $self->paths(@dir)->[0];
    } else {
        $self->home;
    }
}

sub file {
    my ($self, @file) = @_;

    first { -f } map { catfile($_, @file) } $self->path_list;
}

sub renderer {
    my $self = $_[0];

    $renderer ||= Template->new({
        INCLUDE_PATH => $self->paths('templates'),
        ENCODING => 'UTF-8',
        VARIABLES => {
            catmandu => {
                default_home => sub { $self->default_home },
                default_env  => sub { $self->default_env },
                home  => sub { $self->home },
                env   => sub { $self->env },
                stash => sub { $self->stash },
                paths => sub { $self->paths(@_) },
                path  => sub { $self->path(@_) },
                file  => sub { $self->file(@_) },
            },
        },
    });
}

sub render {
    my $self = shift;
    my $tmpl = shift;
    unless (ref $tmpl || $tmpl =~ /\.tt$/) {
        $tmpl = "$tmpl.tt";
    }

    local $Template::Stash::PRIVATE; # we want to see underscored vars

    $self->renderer->process($tmpl, @_)
        or confess $self->renderer->error;
}

sub load_conf_file {
    my $self = shift;
    my $file = catfile(@_);

    if ($file =~ /\.(?:ya?ml|json|pl)$/) {
        -f $file or return;
    } else {
        $file = first { -f } map { "$file.$_" } qw(yaml yml json pl) or return;
    }

    given ($file) {
        when (/\.json$/)  { return JSON::decode_json(slurp($file)) }
        when (/\.ya?ml$/) { return YAML::LoadFile($file) }
        when (/\.pl$/)    { return do $file }
    }
}

no List::Util;
no Cwd;
no File::Spec::Functions;
no File::Basename;
no File::Find;
no File::Slurp;
1;

__END__
=pod

=head1 NAME

Catmandu - web application glue with a focus on storing complex, nested data structures
