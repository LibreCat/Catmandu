package Catmandu;

use Catmandu::Sane;

our $VERSION = '1.2025';

use Catmandu::Env;
use Catmandu::Util qw(:is);
use File::Spec;
use namespace::clean;
use Sub::Exporter::Util qw(curry_method);
use Sub::Exporter -setup => {
    exports => [
        config             => curry_method,
        log                => curry_method,
        store              => curry_method,
        fixer              => curry_method,
        importer           => curry_method,
        exporter           => curry_method,
        validator          => curry_method,
        export             => curry_method,
        export_to_string   => curry_method,
        import_from_string => curry_method
    ],
    collectors => {'-load' => \'_import_load', ':load' => \'_import_load',},
};

sub _import_load {
    my ($self, $value, $data) = @_;
    if (is_array_ref $value) {
        $self->load(@$value);
    }
    else {
        $self->load;
    }
    1;
}

sub _env {
    my ($class, $env) = @_;
    state $loaded_env;
    $loaded_env = $env if defined $env;
    $loaded_env
        ||= Catmandu::Env->new(load_paths => $class->default_load_path);
}

sub log {$_[0]->_env->log}

sub default_load_path {    # TODO move to Catmandu::Env
    my ($class, $path) = @_;
    state $default_path;
    $default_path = $path if defined $path;
    $default_path //= do {
        my $script = File::Spec->rel2abs($0);
        my ($script_vol, $script_path, $script_name)
            = File::Spec->splitpath($script);
        my @dirs = grep length, File::Spec->splitdir($script_path);
        if ($dirs[-1] eq 'bin') {
            pop @dirs;
            File::Spec->catdir(File::Spec->rootdir, @dirs);
        }
        else {
            $script_path;
        }
    };
}

sub load {
    my $class = shift;
    my $paths = [@_ ? @_ : $class->default_load_path];
    my $env   = Catmandu::Env->new(load_paths => $paths);
    $class->_env($env);
    $class;
}

sub roots {
    $_[0]->_env->roots;
}

sub root {
    $_[0]->_env->root;
}

sub config {
    my ($class, $config) = @_;
    if ($config) {
        my $env = Catmandu::Env->new(load_paths => $class->_env->load_paths);
        $env->_set_config($config);
        $class->_env($env);
    }
    $class->_env->config;
}

sub default_store {$_[0]->_env->default_store}

sub store {
    my $class = shift;
    $class->_env->store(@_);
}

sub default_fixer {$_[0]->_env->default_fixer}

sub fixer {
    my $class = shift;
    $class->_env->fixer(@_);
}

sub default_importer {$_[0]->_env->default_importer}

sub default_importer_package {$_[0]->_env->default_importer_package}

sub importer {
    my $class = shift;
    $class->_env->importer(@_);
}

sub default_exporter {$_[0]->_env->default_exporter}

sub default_exporter_package {$_[0]->_env->default_exporter_package}

sub exporter {
    my $class = shift;
    $class->_env->exporter(@_);
}

sub validator {
    my $class = shift;
    $class->_env->validator(@_);
}

sub export {
    my $class    = shift;
    my $data     = shift;
    my $exporter = $class->_env->exporter(@_);
    is_hash_ref($data) ? $exporter->add($data) : $exporter->add_many($data);
    $exporter->commit;
    return;
}

sub export_to_string {
    my $class    = shift;
    my $data     = shift;
    my $name     = shift;
    my %opts     = ref $_[0] ? %{$_[0]} : @_;
    my $str      = "";
    my $exporter = $class->_env->exporter($name, %opts, file => \$str);
    is_hash_ref($data) ? $exporter->add($data) : $exporter->add_many($data);
    $exporter->commit;
    $str;
}

sub import_from_string {
    my $class = shift;
    my $str   = shift;
    my $name  = shift;
    my %opts  = ref $_[0] ? %{$_[0]} : @_;
    $class->_env->importer($name, %opts, file => \$str)->to_array();
}

sub define_importer {
    my $class   = shift;
    my $name    = shift;
    my $package = shift;
    my $options = ref $_[0] ? $_[0] : {@_};
    $class->config->{importer}{$name}
        = {package => $package, options => $options};
}

sub define_exporter {
    my $class   = shift;
    my $name    = shift;
    my $package = shift;
    my $options = ref $_[0] ? $_[0] : {@_};
    $class->config->{exporter}{$name}
        = {package => $package, options => $options};
}

sub define_store {
    my $class   = shift;
    my $name    = shift;
    my $package = shift;
    my $options = ref $_[0] ? $_[0] : {@_};
    $class->config->{store}{$name}
        = {package => $package, options => $options};
}

sub define_fixer {
    my $class = shift;
    my $name  = shift;
    my $fixes = ref $_[0] ? $_[0] : [@_];
    $class->config->{fixer}{$name} = $fixes;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Catmandu - a data toolkit

=head1 SYNOPSIS

    # From the command line

    # Convert data from one format to another
    $ catmandu convert JSON to CSV  < data.json
    $ catmandu convert CSV  to YAML < data.csv
    $ catmandu convert MARC to YAML < data.mrc

    # Fix data, add, delete, change fields
    $ catmandu convert JSON --fix 'move_field(title,my_title)' < data.json
    $ catmandu convert JSON --fix all_my_fixes.txt < data.json

    # Use a moustache preprocessor on the fix script
    $ catmandu convert JSON --fix all_my_fixes.txt --var opt1=foo --var opt2=bar < data.json

    # run a fix script
    $ catmandu run myfixes.fix

    # or, create an executable fix script
    $ cat myfixes.fix
    #!/usr/local/bin/catmandu run
    do importer(OAI,url:"http://biblio.ugent.be/oai")
        retain(_id)
    end
    $ chmod 755 myfixes.fix
    $ ./myfixes.fix

=head1 DESCRIPTION

Catmandu provides a command line tools for the conversion of various data 
formats including: JSON, YAML, RDF, CSV, TSV, XML and even Excel. Using 
extension modules, specialized conversions for metadata formats using 
in libraries, archives and museums is also supports. We provide support 
for MARC, MAB, MODS, OAI-PMH, PICA, PNX, RIS, LIDO, SRU and Z39.50. 

Specialized conversions require a mapping language. This is implemented in 
Catmandu using the `Fix` language. For a short introduction read
L<Catmandu::Introduction>.  Online tutorials can be found at the end of this document.

=head1 INSTALL 

=head2 From Source

    # Clone the directory
    git clone https://github.com/LibreCat/Catmandu

    # Build
    cd Catmandu
    cpanm -n -q --installdeps --skip-satisfied .
    perl Build.PL && ./Build && ./Build install

=head2 Using Docker

    docker build -t librecat/catmandu .
    
    # Run catmandu with access to you local files at <YourDrive>
    docker run -v <YourDrive>:/home/catmandu/Home  -it librecat/catmandu

    # E.g.
    docker run -v C:\Users\alice:/home/catmandu/Home -it librecat/catmandu

=head1 INSTALL EXTENSIONS

    cpanm install <PackageName>

    # E.g.
    cpanm install Catmandu::MARC

=head1 POPULAR EXTENSIONS

L<Catmandu::Breaker>

L<Catmandu::Identifier>

L<Catmandu::MARC>

L<Catmandu::OAI>

L<Catmandu::PICA>

L<Catmandu::RDF>

L<Catmandu::SRU>

L<Catmandu::Stat>

L<Catmandu::Template>

L<Catmandu::Validator>

L<Catmandu::XLS>

L<Catmandu::XSD>

L<Catmandu::Z3950>

=head1 SEE ALSO

=over 4

=item introduction

L<Catmandu::Introduction>

=item documentation

L<http://librecat.org/>

=item blog

L<https://librecatproject.wordpress.com/>

=item step-by-step introduction from basics

L<https://librecatproject.wordpress.com/2014/12/01/day-1-getting-catmandu/>

=item command line client

L<catmandu>

=item Perl API

L<Catmandu::PerlAPI>

=back

=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 CONTRIBUTORS

Patrick Hochstenbach, C<< patrick.hochstenbach at ugent.be >>

Nicolas Franck, C<< nicolas.franck at ugent.be >>

Johann Rolschewski, C<< jorol at cpan.org >>

Vitali Peil, C<< vitali.peil at uni-bielefeld.de >>

Jakob Voss, C<< nichtich at cpan.org >>

Magnus Enger, C<< magnus at enger.priv.no >>

Christian Pietsch, C<< christian.pietsch at uni-bielefeld.de >>

Dave Sherohman, C<< dave.sherohman at ub.lu.se >>

Snorri Briem, C<< snorri.briem at ub.lu.se >>

Pieter De Praetere, C<< pieter.de.praetere at helptux.be >>

Doug Bell

Upsana, C<< me at upasana.me >>

Stefan Weil

Tom Hukins

Michal Josef Špaček C<<michal.josef.spacek at gmail.com>>

=head1 QUESTIONS, ISSUES & BUG REPORTS

For any questions on the use of our modules, or bug reports, or feature requests,
please use our issue tracker at:

    https://github.com/LibreCat/Catmandu/issues

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
