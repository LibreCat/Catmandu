package Catmandu::Project;

use namespace::autoclean -also => [qw(_file _dir)];
use 5.010;
use Moose;
use Catmandu::Dist qw(share_dir);
use List::Util qw(first);
use Template;
use Path::Class ();
use Hash::Merge::Simple qw(merge);
use File::Slurp qw(slurp);
use YAML ();
use JSON ();

with qw(MooseX::LogDispatch);

sub _file { Path::Class::file(@_) }
sub _dir { Path::Class::dir(@_) }

has home     => (is => 'ro', isa => 'Str', required => 1);
has env      => (is => 'ro', isa => 'Str', required => 1);
has stack    => (is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_stack');
has conf     => (is => 'ro', isa => 'HashRef',  lazy => 1, builder => '_build_conf');
has template => (is => 'ro', isa => 'Template', lazy => 1, builder => '_build_template');
has _stash   => (is => 'ro', isa => 'HashRef',  init_arg => undef, lazy => 1, builder => '_build_stash');
has log_dispatch_conf => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    required => 1,
    builder => '_build_log_dispatch_conf',
);

sub _build_stack {
    my $self = shift;
    my $file = first { -f _file($self->home, $_)->stringify } qw(catmandu.yml catmandu.yaml);
    $file or return ['catmandu-base'];
    my $dirs = YAML::LoadFile($file);
    if (! grep /^catmandu-base$/, @$dirs) {
        push @$dirs, 'catmandu-base';
    }
    [ map { _dir($_)->resolve->stringify } @$dirs ];
}

sub _build_conf {
    my $self = shift;
    my $conf = {};

    foreach my $conf_path ( reverse @{$self->paths('conf')} ) {
        _dir($conf_path)->recurse(depthfirst => 1, callback => sub {
            my $file = shift;
            my $path = $file->stringify;
            my $hash;
            -f $path or return;
            given ($path) {
                when (/\.json$/)  { $hash = JSON::decode_json(slurp($file)) }
                when (/\.ya?ml$/) { $hash = YAML::LoadFile($path) }
                when (/\.pl$/)    { $hash = do $path }
            }
            if (ref $hash eq 'HASH') {
                $conf = merge($conf, $hash);
            }
        });
    }

    # load env specific conf
    if (my $hash = delete $conf->{$self->env}) {
        $conf = merge($conf, $hash);
    }

    $conf;
}

sub _build_template {
    my $self = shift;
    my $args = $self->conf->{template} || {};
    Template->new({
        INCLUDE_PATH => $self->paths('template'),
        %$args,
    });
}

sub _build_stash {
    {};
}

sub _build_log_dispatch_conf {
    my $self = shift;
    $self->conf->{logger} || {
        class     => 'Log::Dispatch::Screen',
        min_level => 'debug',
        stderr    => 1,
        newline   => 1,
        format    => '[%p] %m at %F line %L',
    };
}

sub print_template {
    my ($self, $file, $vars, @rest) = @_;
    $vars ||= {};
    $file = "$file.tt" if ! ref $file && $file !~ /\.tt$/;
    $vars->{project} = $self;
    $self->template->process($file, $vars, @rest) or
        confess $self->template->error;
}

sub stash {
    my $self = shift;
    my $hash = $self->_stash;
    return $hash          if @_ == 0;
    return $hash->{$_[0]} if @_ == 1;
    my %pairs = @_;
    while (my ($key, $val) = each %pairs) {
        $hash->{$key} = $val;
    }
    $hash;
}

sub paths {
    my ($self, $dir) = @_;
    my $stack = $self->stack;
    my $paths = [ $self->home,
                    map { _dir($_)->is_absolute ? $_ : 
                        _dir(/^catmandu-/ ? share_dir : $self->home, $_)->stringify; } @$stack ];
    if ($dir) {
        [ grep { -d $_ } map { _dir($_, $dir)->stringify } @$paths ];
    } else {
        $paths;
    }
}

sub path {
    my ($self, $dir) = @_;
    $self->paths($dir)->[0];
}

sub files {
    my ($self, $dir, $file) = @_;
    my $paths = $self->paths($dir);
    [ grep { -f $_ } map { _file($_, $file)->stringify } @$paths ];
}

sub file {
    my ($self, $dir, $file) = @_;
    $self->files($dir, $file)->[0];
}

sub lib {
    @{$_[0]->paths('lib')};
}

1;

