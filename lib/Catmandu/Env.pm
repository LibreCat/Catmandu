package Catmandu::Env;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Catmandu::Util qw(require_package use_lib read_yaml read_json :is :check);
use Catmandu::Fix;
use Config::Onion;
use File::Spec;
use Moo;
require Catmandu;
use namespace::clean;

with 'Catmandu::Logger';

sub _search_up {
    my $dir = $_[0];
    my @dirs = grep length, File::Spec->splitdir(Catmandu->default_load_path);
    for (; @dirs; pop @dirs) {
        my $path = File::Spec->catdir(File::Spec->rootdir, @dirs);
        opendir my $dh, $path or last;
        return $path
            if grep {-r File::Spec->catfile($path, $_)}
            grep /^catmandu.+(?:yaml|yml|json|pl)$/, readdir $dh;
    }
    Catmandu->default_load_path;
}

has load_paths => (
    is      => 'ro',
    default => sub {[]},
    coerce  => sub {
        [
            map {File::Spec->canonpath($_)}
                map {$_ eq ':up' ? _search_up($_) : $_} split /,/,
            join ',',
            ref $_[0] ? @{$_[0]} : $_[0]
        ];
    },
);

has config => (is => 'rwp', default => sub {+{}});

has stores => (is => 'ro', default => sub {+{}});
has fixers => (is => 'ro', default => sub {+{}});

has default_store            => (is => 'ro', default => sub {'default'});
has default_fixer            => (is => 'ro', default => sub {'default'});
has default_importer         => (is => 'ro', default => sub {'default'});
has default_exporter         => (is => 'ro', default => sub {'default'});
has default_importer_package => (is => 'ro', default => sub {'JSON'});
has default_exporter_package => (is => 'ro', default => sub {'JSON'});

has store_namespace => (is => 'ro', default => sub {'Catmandu::Store'});
has fixes_namespace => (is => 'ro', default => sub {'Catmandu::Fix'})
    ;    # TODO unused

has importer_namespace => (is => 'ro', default => sub {'Catmandu::Importer'});
has exporter_namespace => (is => 'ro', default => sub {'Catmandu::Exporter'});

sub BUILD {
    my ($self) = @_;

    my @config_dirs = @{$self->load_paths};
    my @lib_dirs;

    for my $dir (@config_dirs) {
        if (!-d $dir) {
            Catmandu::Error->throw("load path $dir doesn't exist");
        }

        my $lib_dir = File::Spec->catdir($dir, 'lib');

        if (-d $lib_dir && -r $lib_dir) {
            push @lib_dirs, $lib_dir;
        }
    }

    if (@config_dirs) {
        my @globs = map {
            my $dir = $_;
            map {File::Spec->catfile($dir, "catmandu*.$_")}
                qw(yaml yml json pl)
        } reverse @config_dirs;

        my $config = Config::Onion->new(prefix_key => '_prefix');
        $config->load_glob(@globs);

        if ($self->log->is_debug) {
            use Data::Dumper;
            $self->log->debug(Dumper($config->get));
        }
        $self->_set_config($config->get);
    }

    if (@lib_dirs) {
        lib->import(@lib_dirs);
    }
}

sub load_path {
    $_[0]->load_paths->[0];
}

sub roots {
    goto &load_paths;
}

sub root {
    goto &load_path;
}

sub store {
    my $self = shift;
    my $name = shift;

    my $stores = $self->stores;

    my $key = $name || $self->default_store;

    $stores->{$key} || do {
        my $ns = $self->store_namespace;
        if (my $c = $self->config->{store}{$key}) {
            check_hash_ref($c);
            check_string(my $package = $c->{package});
            my $opts = $c->{options} || {};
            if (@_ > 1) {
                $opts = {%$opts, @_};
            }
            elsif (@_ == 1) {
                $opts = {%$opts, %{$_[0]}};
            }
            return $stores->{$key}
                = require_package($package, $ns)->new($opts);
        }
        if ($name) {
            return require_package($name, $ns)->new(@_);
        }
        Catmandu::BadArg->throw("unknown store " . $self->default_store);
        }
}

sub fixer {
    my $self = shift;

    # it's already a fixer
    if (is_instance($_[0], 'Catmandu::Fix')) {
        return $_[0];
    }

    # an array ref of fixes
    if (is_array_ref($_[0])) {
        return Catmandu::Fix->new(fixes => $_[0]);
    }

    # a single fix
    if (is_able($_[0], 'fix')) {
        return Catmandu::Fix->new(fixes => [$_[0]]);
    }

    # try to load from config
    my $key = $_[0] || $self->default_fixer;

    my $fixers = $self->fixers;

    $fixers->{$key} || do {
        if (my $fixes = $self->config->{fixer}{$key}) {
            return $fixers->{$key} = Catmandu::Fix->new(fixes => $fixes);
        }
        return Catmandu::Fix->new(fixes => [@_]);
    };
}

sub importer {
    my $self = shift;
    my $name = shift;
    my $ns   = $self->importer_namespace;
    if (exists $self->config->{importer}) {
        if (my $c
            = $self->config->{importer}{$name || $self->default_importer})
        {
            check_hash_ref($c);
            my $package = $c->{package} || $self->default_importer_package;
            my $opts    = $c->{options} || {};
            if (@_ > 1) {
                $opts = {%$opts, @_};
            }
            elsif (@_ == 1) {
                $opts = {%$opts, %{$_[0]}};
            }
            return require_package($package, $ns)->new($opts);
        }
    }
    require_package($name || $self->default_importer_package, $ns)->new(@_);
}

sub exporter {
    my $self = shift;
    my $name = shift;

    return $name
        if (is_invocant($name) && ref($name) =~ /^Catmandu::Exporter/);

    my $ns = $self->exporter_namespace;
    if (exists $self->config->{exporter}) {
        if (my $c
            = $self->config->{exporter}{$name || $self->default_exporter})
        {
            check_hash_ref($c);
            my $package = $c->{package} || $self->default_exporter_package;
            my $opts    = $c->{options} || {};
            if (@_ > 1) {
                $opts = {%$opts, @_};
            }
            elsif (@_ == 1) {
                $opts = {%$opts, %{$_[0]}};
            }
            return require_package($package, $ns)->new($opts);
        }
    }
    require_package($name || $self->default_exporter_package, $ns)->new(@_);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Env - A catmandu configuration file loader

=head1 SYNOPSIS

    use Catmandu::Env;

    my $env = Catmandu::Env->new(load_paths => [ '/etc/catmandu '] );
    my $env = Catmandu::Env->new(load_paths => [ ':up'] );

    my $store    = $env->store('mongodb');
    my $importer = $env->importer('loc');
    my $exporter = $env->exporter('europeana');
    my $fixer    = $env->fixer('my_fixes');
    my $conf     = $env->config;

=head1 DESCRIPTION

This class loads the catmandu.*.pl, catmandu.*.json, catmandu.*.yml and catmandu.*.yaml file from
all provided load_paths. Programmers are advised *not* to use this class directly 
but use the equivalent functionality provided in the Catmandu package:

     Catmandu->load('/etc/catmandu');
     Catmandu->load(':up');

     my $store    = Catmandu->store('mongodb');
     my $importer = Catmandu->importer('loc');
     my $exporter = Catmandu->exporter('europeana');
     my $fixer    = Catmandu->fixer('my_fixes');
     my $conf     = Catmandu->config;

=head1 SEE ALSO

L<Catmandu>

=cut
