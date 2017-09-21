package Catmandu::Fix::include;

use Catmandu::Sane;

our $VERSION = '1.0605';

use Moo;
use Catmandu;
use Catmandu::Fix;
use File::Spec qw();
use Cwd qw();
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

has path => (fix_arg => 1);
has _path => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {

        my $self = $_[0];

        my $path = $self->path();
        my $real_path;
        my $load_paths = Catmandu->_env->load_paths;

        if (File::Spec->file_name_is_absolute($path)) {
            $real_path = $path;
        }
        else {
            for my $p (@$load_paths) {
                my $n = File::Spec->catfile($p, $path);
                if (-r $n) {
                    $real_path = Cwd::realpath($n);
                    last;
                }
            }

        }

        die("unable to find $path in load_path of Catmandu (load_path:  "
                . join(',', @$load_paths) . ")")
            unless defined $real_path;
        $real_path;
    }
);

has _fixer => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        Catmandu::Fix->new(fixes => [$_[0]->_path()]);
    }
);

sub fix {
    my ($self, $data) = @_;
    $self->_fixer()->fix($data);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::include - include fixes from another file

=head1 SYNOPSIS

    include('/path/to/myfixes.txt')

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
