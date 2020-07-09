package Catmandu::Env;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Catmandu::Util qw(require_package use_lib read_yaml read_json :is :check);
use Catmandu::Fix;
use Config::Onion;
use File::Spec;
use Moo;
require Catmandu;
use namespace::clean;

with 'Catmandu::Logger';

sub _search_up {
    my $dir  = $_[0];
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
            map     {File::Spec->canonpath($_)}
                map {$_ eq ':up' ? _search_up($_) : $_} split /,/,
            join ',',
            ref $_[0] ? @{$_[0]} : $_[0]
        ];
    },
);

has config => (is => 'rwp', default => sub {+{}});

has stores     => (is => 'ro', default => sub {+{}});
has validators => (is => 'ro', default => sub {+{}});
has fixers     => (is => 'ro', default => sub {+{}});

has default_store     => (is => 'ro', default => sub {'default'});
has default_importer  => (is => 'ro', default => sub {'default'});
has default_exporter  => (is => 'ro', default => sub {'default'});
has default_validator => (is => 'ro', default => sub {'default'});
has default_fixer     => (is => 'ro', default => sub {'default'});

has default_store_package     => (is => 'ro');
has default_importer_package  => (is => 'ro', default => sub {'JSON'});
has default_exporter_package  => (is => 'ro', default => sub {'JSON'});
has default_validator_package => (is => 'ro');

has store_namespace    => (is => 'ro', default => sub {'Catmandu::Store'});
has importer_namespace => (is => 'ro', default => sub {'Catmandu::Importer'});
has exporter_namespace => (is => 'ro', default => sub {'Catmandu::Exporter'});
has validator_namespace =>
    (is => 'ro', default => sub {'Catmandu::Validator'});

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

sub store {
    my $self = shift;
    $self->_named_package('store', $self->store_namespace,
        $self->default_store, $self->default_store_package,
        $self->stores,        @_);
}

sub importer {
    my $self = shift;
    $self->_named_package('importer', $self->importer_namespace,
        $self->default_importer, $self->default_importer_package,
        undef,                   @_);
}

sub exporter {
    my $self = shift;
    $self->_named_package('exporter', $self->exporter_namespace,
        $self->default_exporter, $self->default_exporter_package,
        undef,                   @_);
}

sub validator {
    my $self = shift;
    $self->_named_package(
        'validator',              $self->validator_namespace,
        $self->default_validator, $self->default_validator_package,
        $self->validators,        @_
    );
}

sub _named_package {
    my $self            = shift;
    my $type            = shift;
    my $ns              = shift;
    my $default_name    = shift;
    my $default_package = shift;
    my $cache           = shift;
    my $name            = shift;
    my $key             = $name || $default_name;

    return $name if is_instance($name) && index(ref($name), $ns) == 0;

    # return cached instance if no arguments are given
    if ($cache && !@_ and my $instance = $cache->{$key}) {
        return $instance;
    }

    if (exists $self->config->{$type}) {
        if (my $c = $self->config->{$type}{$key}) {
            check_hash_ref($c);
            check_string(my $package = $c->{package} || $default_package);
            my $opts = check_hash_ref($c->{options} || {});
            if (@_ > 1) {
                $opts = {%$opts, @_};
            }
            elsif (@_ == 1) {
                $opts = {%$opts, %{$_[0]}};
            }
            my $instance = require_package($package, $ns)->new($opts);

            # cache this instance if no arguments are given
            if ($cache && !@_) {
                $cache->{$key} = $instance;
            }

            return $instance;
        }
    }

    check_string(my $package = $name || $default_package);
    require_package($package, $ns)->new(@_);
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
all provided load_paths. Programmers are advised I<not> to use this class directly 
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
