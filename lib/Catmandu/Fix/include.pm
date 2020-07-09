package Catmandu::Fix::include;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu;
use Catmandu::Fix;
use File::Spec;
use Cwd qw(realpath);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

has path   => (fix_arg => 1);
has _files => (is      => 'lazy');
has _fixer => (is      => 'lazy');

sub _build__files {
    my ($self) = @_;
    my $path = $self->path;

    if ($path =~ /\*/) {    # path is glob pattern
        return $self->_find_glob($path);
    }

    [$self->_find_file($path)];
}

sub _find_file {
    my ($self, $path) = @_;
    my $roots = Catmandu->roots;
    my $file;

    if (File::Spec->file_name_is_absolute($path)) {
        $file = $path;
    }
    else {
        for my $root (@$roots) {
            my $f = File::Spec->catfile($root, $path);
            if (-r $f) {
                $file = $f;
                last;
            }
        }

    }

    Catmandu::Error->throw(
        "unable to find $path in " . join(',', @$roots) . ")")
        unless defined $file;

    realpath($file);
}

sub _find_glob {
    my ($self, $path) = @_;
    my $roots = Catmandu->roots;

    if (File::Spec->file_name_is_absolute($path)) {
        return [sort map {realpath($_)} grep {-r $_} glob $path];
    }

    my %seen;
    my $files = [];

    for my $root (@$roots) {
        my $glob = File::Spec->catfile($root, $path);
        for my $file (glob $glob) {
            my $rel_path = File::Spec->abs2rel($file, $root);
            next if $seen{$rel_path};
            if (-r $file) {
                push @$files, realpath($file);
                $seen{$rel_path} = 1;
            }
        }
    }

    [sort @$files];
}

sub _build__fixer {
    my ($self) = @_;
    my $files = $self->_files;
    return unless @$files;
    Catmandu::Fix->new(fixes => $files);
}

sub fix {
    my ($self, $data) = @_;
    my $fixer = $self->_fixer;
    return $data unless $fixer;
    $fixer->fix($data);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::include - include fixes from another file

=head1 SYNOPSIS

    include('/path/to/myfixes.txt')
    include('fixes/*.fix')

=head1 NOTES

=over 4

=item path is relative to a Catmandu load path

    #1. a catmandu load path is a directory where a catmandu configuration file can be found
    #2. as there are multiple load paths, it will loop through all the path, and include the first file it can find
    #3. in catmandu, the default_load_path is either
    #   3.1. the directory of the running script
    #   3.2. the parent directory of the running script if the directory is 'bin'

    #use default load_path
    #called from script "/opt/catmandu-project/fix.pl"
    #default_load_path: /opt/catmandu-project
    #file must be located at "/opt/catmandu-project/fixes/myfixes.txt"
    Catmandu->fixer("include('fixes/myfixes.txt')");

    #use default load_path
    #called from script "/opt/catmandu-project/bin/fix.pl"
    #default_load_path: /opt/catmandu-project (notice the absence of 'bin')
    #file must be located at "/opt/catmandu-project/fixes/myfixes.txt"
    Catmandu->fixer("include('fixes/myfixes.txt')");

    #load fixes, located at /opt/catmandu-project/fixes/myfixes.txt
    Catmandu->load("/opt/catmandu-project");
    Catmandu->fixer("include('fixes/myfixes.txt')");

    #look for 'fixes/myfixes.txt' in /opt/catmandu-project2, and if that fails in /opt/catmandu-project-1
    Catmandu->load("/opt/catmandu-project2","/opt/catmandu-project-1");
    Catmandu->fixer("include('fixes/myfixes.txt')");

    #if "/opt/catmandu-project/fixes/myfixes2.txt" does not exists, the fix will fail
    Catmandu->load("/opt/catmandu-project");
    Catmandu->fixer("include('fixes/myfixes2.txt)");


=item circular references are not detected

=item if the 'include' is enclosed within an if-statement, the fixes are inserted in the control structure, but only executed if the if-statement evaluates to 'true'.

    #the fixes in the file 'add_address_fields.txt' are only executed when field 'name' has content,
    #but, the fixes are included in the control structure.
    if all_match('name','.+')
        include('add_address_fields.txt')
    end

=back

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
