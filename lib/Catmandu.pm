package Catmandu;

our $VERSION = '0.1';

use Catmandu::Sane;
use Catmandu::Util qw(:load :read :is :check);
use File::Spec;

use Sub::Exporter::Util qw(curry_method);
use Sub::Exporter -setup => {
    exports => [config   => curry_method,
                store    => curry_method,
                importer => curry_method,
                exporter => curry_method,
                export   => curry_method,
                export_to_string => curry_method],
};

sub default_load_path {
    my ($class, @paths) = @_;
    state $default_path;
    $default_path = join ',', @paths if @paths;
    $default_path //= do {
        my $script = File::Spec->rel2abs($0);
        my ($script_vol, $script_path, $script_name) = File::Spec->splitpath($0);
        $script_path;
    }
}

sub load {
    my ($self, @paths) = @_;

    push @paths, $self->default_load_path unless @paths;

    @paths = map { File::Spec->rel2abs($_) } split /,/, join ',', @paths;

    for my $path (@paths) {
        my @dirs = grep length, File::Spec->splitdir($path);

        for (;@dirs;pop @dirs) {
            my $dir = File::Spec->catdir(File::Spec->rootdir, @dirs);

            opendir my $dh, $dir or last;

            my @files = sort
                        grep { -f -r File::Spec->catfile($dir, $_) }
                        grep { /^catmandu\./ }
                        readdir $dh;
            for my $file (@files) {
                if (my ($keys, $ext) = $file =~ /^catmandu(.*)\.(pl|yaml|yml|json)$/) {
                    $file = File::Spec->catfile($dir, $file);

                    my $config = $self->config;
                    for (split '.', $keys) {
                        $config = $config->{$_} ||= {};
                    }
                    my $c;
                    given ($ext) {
                        when ('pl')            { $c = do $file }
                        when (['yaml', 'yml']) { $c = read_yaml($file) }
                        when ('json')          { $c = read_json($file) }
                    }
                    for (keys %$c) {
                        $config->{$_} = $c->{$_};
                    }
                }
            }

            if (@files) {
                my $lib_dir = File::Spec->catdir($dir, 'lib');
                if (-d -r $lib_dir) {
                    use_lib $lib_dir;
                }

                last;
            }
        }
    }
}

sub config {
    state $config = {};
}

my $stores = {};

sub default_store { 'default' }

sub store {
    my $self = shift;
    my $sym = check_string(shift || $self->default_store);

    $stores->{$sym} || do {
        if (my $cfg = $self->config->{store}{$sym}) {
            check_hash_ref($cfg);
            check_string(my $pkg = $cfg->{package});
            check_hash_ref(my $opts = $cfg->{options} || {});
            $opts = is_hash_ref($_[0])
                ? {%$opts, %{$_[0]}}
                : {%$opts, @_};
            $stores->{$sym} = require_package($pkg, 'Catmandu::Store')->new($opts);
        } else {
            require_package($sym, 'Catmandu::Store')->new(@_);
        }
    };
}

sub importer {
    my $self = shift;
    my $sym = check_string(shift);
    if (my $cfg = $self->config->{importer}{$sym}) {
        check_hash_ref($cfg);
        check_string(my $pkg = $cfg->{package});
        check_hash_ref(my $opts = $cfg->{options} || {});
        $opts = is_hash_ref($_[0])
            ? {%$opts, %{$_[0]}}
            : {%$opts, @_};
        require_package($pkg, 'Catmandu::Importer')->new($opts);
    } else {
        require_package($sym, 'Catmandu::Importer')->new(@_);
    }
}

sub exporter {
    my $self = shift;
    my $sym = check_string(shift);
    if (my $cfg = $self->config->{exporter}{$sym}) {
        check_hash_ref($cfg);
        check_string(my $pkg = $cfg->{package});
        check_hash_ref(my $opts = $cfg->{options} || {});
        $opts = is_hash_ref($_[0])
            ? {%$opts, %{$_[0]}}
            : {%$opts, @_};
        require_package($pkg, 'Catmandu::Exporter')->new($opts);
    } else {
        require_package($sym, 'Catmandu::Exporter')->new(@_);
    }
}

sub export {
    my $self = shift;
    my $data = shift;
    my $exporter = $self->exporter(@_);
    is_hash_ref($data)
        ? $exporter->add($data)
        : $exporter->add_many($data);
    $exporter->commit;
    return;
}

sub export_to_string {
    my $self = shift;
    my $data = shift;
    my $sym  = shift;
    my %opts = is_hash_ref($_[0]) ? %{$_[0]} : @_;
    my $str  = "";
    my $exporter = $self->exporter($sym, %opts, file => \$str);
    is_hash_ref($data)
        ? $exporter->add($data)
        : $exporter->add_many($data);
    $exporter->commit;
    $str;
}

1;

=head1 NAME

Catmandu - a data toolkit

=cut
