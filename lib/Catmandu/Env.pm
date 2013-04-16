package Catmandu::Env;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(require_package use_lib read_yaml read_json :is :check);
use Catmandu::Fix;
use File::Spec;
use Moo;

with 'MooX::Log::Any';

has load_paths => (
    is      => 'ro',
    default => sub { [] },
    coerce  => sub {
        [map { File::Spec->rel2abs($_) }
            split /,/, join ',', ref $_[0] ? @{$_[0]} : $_[0]];
    },
);

has roots => (
    is      => 'ro',
    default => sub { [] },
);

has config => (is => 'ro', default => sub { +{} });
has stores => (is => 'ro', default => sub { +{} });
has fixers => (is => 'ro', default => sub { +{} });

has default_store => (is => 'ro', default => sub { 'default' });
has default_fixer => (is => 'ro', default => sub { 'default' });
has default_importer => (is => 'ro', default => sub { 'default' });
has default_exporter => (is => 'ro', default => sub { 'default' });
has default_importer_package => (is => 'ro', default => sub { 'JSON' });
has default_exporter_package => (is => 'ro', default => sub { 'JSON' });
has store_namespace => (is => 'ro', default => sub { 'Catmandu::Store' });
has fixes_namespace => (is => 'ro', default => sub { 'Catmandu::Fix' }); # TODO unused
has importer_namespace => (is => 'ro', default => sub { 'Catmandu::Importer' });
has exporter_namespace => (is => 'ro', default => sub { 'Catmandu::Exporter' });

sub BUILD {
    my ($self) = @_;

    for my $load_path (@{$self->load_paths}) {
        my @dirs = grep length, File::Spec->splitdir($load_path);

        for (;@dirs;pop @dirs) {
            my $path = File::Spec->catdir(File::Spec->rootdir, @dirs);

            opendir my $dh, $path or last;

            my @files = sort
                        grep { -f -r File::Spec->catfile($path, $_) }
                        grep { /^catmandu\./ }
                        readdir $dh;
            for my $file (@files) {
                if (my ($keys, $ext) = $file =~ /^catmandu(.*)\.(pl|yaml|yml|json)$/) {
                    $keys = substr $keys, 1 if $keys; # remove leading dot

                    $file = File::Spec->catfile($path, $file);

                    my $config = $self->config;
                    my $c;

                    $config = $config->{$_} ||= {} for split /\./, $keys;

                    given ($ext) {
                        when ('pl')    { $c = do $file }
                        when (/ya?ml/) { $c = read_yaml($file) }
                        when ('json')  { $c = read_json($file) }
                    }
                    $config->{$_} = $c->{$_} for keys %$c;
                }
            }

            if (@files) {
                unshift @{$self->roots}, $path;

                my $lib_path = File::Spec->catdir($path, 'lib');
                if (-d -r $lib_path) {
                    use_lib $lib_path;
                }

                last;
            }
        }
    }
}

sub root {
    my ($self) = @_; $self->roots->[0];
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
            } elsif (@_ == 1) {
                $opts = {%$opts, %{$_[0]}};
            }
            return $stores->{$key} = require_package($package, $ns)->new($opts);
        }
        if ($name) {
            return require_package($name, $ns)->new(@_);
        }
        Catmandu::BadArg->throw("unknown store ".$self->default_store);
    }
}

sub fixer {
    my $self = shift;
    if (ref $_[0]) {
        return Catmandu::Fix->new(fixes => $_[0]);
    }

    my $key = $_[0] || $self->default_fixer;

    my $fixers = $self->fixers;

    $fixers->{$key} || do {
        if (my $fixes = $self->config->{fixer}{$key}) {
            return $fixers->{$key} = Catmandu::Fix->new(fixes => $fixes);
        }
        return Catmandu::Fix->new(fixes => \@_);
    }
}

sub importer {
    my $self = shift;
    my $name = shift;
    my $ns = $self->importer_namespace;
    if (my $c = $self->config->{importer}{$name || $self->default_importer}) {
        check_hash_ref($c);
        my $package = $c->{package} || $self->default_importer_package;
        my $opts    = $c->{options} || {};
        if (@_ > 1) {
            $opts = {%$opts, @_};
        } elsif (@_ == 1) {
            $opts = {%$opts, %{$_[0]}};
        }
        return require_package($package, $ns)->new($opts);
    }
    require_package($name ||
        $self->default_importer_package, $ns)->new(@_);
}

sub exporter {
    my $self = shift;
    my $name = shift;
    my $ns = $self->exporter_namespace;
    if (my $c = $self->config->{exporter}{$name || $self->default_exporter}) {
        check_hash_ref($c);
        my $package = $c->{package} || $self->default_exporter_package;
        my $opts    = $c->{options} || {};
        if (@_ > 1) {
            $opts = {%$opts, @_};
        } elsif (@_ == 1) {
            $opts = {%$opts, %{$_[0]}};
        }
        return require_package($package, $ns)->new($opts);
    }
    require_package($name ||
        $self->default_exporter_package, $ns)->new(@_);
}

1;
