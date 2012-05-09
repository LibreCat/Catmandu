package Catmandu;

use Catmandu::Sane;
use Catmandu::Util qw(require_package use_lib read_yaml read_json :is :check);
use File::Spec;

=head1 NAME

Catmandu - a data toolkit

=head1 VERSION

Version 0.0102

=cut

our $VERSION = '0.0102';

=head1 SYNOPSIS

    use Catmandu;

    Catmandu->load;
    Catmandu->load('/config/path', '/another/config/path');

    Catmandu->store->bag('projects')->count;

    Catmandu->config;
    Catmandu->config->{foo} = 'bar';

    use Catmandu -all;
    use Catmandu qw(config store);
    use Catmandu -load;
    use Catmandu -all -load => [qw(/config/path' '/another/config/path)];

=head1 EXPORTS

=over

=item config

Same as C<< Catmandu->config >>.

=item store

Same as C<< Catmandu->store >>.

=item importer

Same as C<< Catmandu->importer >>.

=item exporter

Same as C<< Catmandu->exporter >>.

=item export

Same as C<< Catmandu->export >>.

=item export_to_string

Same as C<< Catmandu->export_to_string >>.

=item -all/:all

Import everything.

=item -load/:load

    use Catmandu -load;
    use Catmandu -load => [];
    # is the same as
    Catmandu->load;

    use Catmandu -load => ['/config/path'];
    # is the same as
    Catmandu->load('/config/path');

=back

=cut

use Sub::Exporter::Util qw(curry_method);
use Sub::Exporter -setup => {
    exports => [config   => curry_method,
                store    => curry_method,
                importer => curry_method,
                exporter => curry_method,
                export   => curry_method,
                export_to_string => curry_method],
    collectors => {
        '-load' => \'_import_load',
        ':load' => \'_import_load',
    },
};

sub _import_load {
    my ($self, $value, $data) = @_;
    if (is_array_ref $value) {
        $self->load(@$value);
    } else {
        $self->load;
    }
    1;
}

=head1 METHODS

=head2 default_load_path
=head2 default_load_path('/default/path')

=cut

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

=head2 load
=head2 load('/path', '/another/path')

=cut

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

=head2 config

=cut

sub config {
    state $config = {};
}

my $stores = {};

=head2 default_store

=cut

sub default_store { 'default' }

=head2 store

=cut

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

=head2 importer

=cut

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

=head2 exporter

=cut

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

=head2 export

=cut

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

=head2 export_to_string

=cut

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

=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ghent University Library

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
