use MooseX::Declare;

class Catmandu::Project
    with MooseX::LogDispatch
    is dirty {
    use 5.010;
    use Catmandu::Dist qw(share_dir);
    use List::Util qw(first);
    use Template;
    use Path::Class ();
    use Hash::Merge ();
    use YAML ();
    use JSON ();

    sub _file { Path::Class::File->new(@_) }
    sub _dir { Path::Class::Dir->new(@_) }

    clean;

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

    method _build_stack () {
        my $file = first { -f _file($self->home, $_)->stringify } qw(catmandu.yml catmandu.yaml);
        $file or return ['catmandu-base'];
        my $dirs = YAML::LoadFile($file);
        if (! grep /^catmandu-base$/, @$dirs) {
            push @$dirs, 'catmandu-base';
        }
        [ map { _dir($_)->resolve->stringify } @$dirs ];
    }

    method _build_conf () {
        my $merger = Hash::Merge->new('RIGHT_PRECEDENT');
        my $conf   = {};

        foreach my $conf_path ( reverse @{$self->paths('conf')} ) {
            _dir($conf_path)->recurse(depthfirst => 1, callback => sub {
                my $file = shift;
                my $path = $file->stringify;
                my $hash;
                -f $path or return;
                given ($path) {
                    when (/\.json$/)  { $hash = JSON::decode_json($file->slurp) }
                    when (/\.ya?ml$/) { $hash = YAML::LoadFile($path) }
                    when (/\.pl$/)    { $hash = do $path }
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

    method _build_template () {
        my $args = $self->conf->{template} || {};
        Template->new({
            INCLUDE_PATH => $self->paths('template'),
            %$args,
        });
    }

    method _build_stash {
        {};
    }

    method _build_log_dispatch_conf {
        $self->conf->{logger} || {
            class     => 'Log::Dispatch::Screen',
            min_level => 'debug',
            stderr    => 1,
            newline   => 1,
            format    => '[%p] %m at %F line %L',
        };
    }

    method print_template (Str|ScalarRef[Str]|GlobRef $file, HashRef $vars = {}, @rest) {
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

    method paths (Str $dir?) {
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

    method path (Str $dir?) {
        $self->paths($dir)->[0];
    }

    method files (Str $dir, Str $file) {
        my $paths = $self->paths($dir);
        [ grep { -f $_ } map { _file($_, $file)->stringify } @$paths ];
    }

    method file (Str $dir, Str $file) {
        $self->files($dir, $file)->[0];
    }

    method lib () {
        @{$self->paths('lib')};
    }
}

1;

