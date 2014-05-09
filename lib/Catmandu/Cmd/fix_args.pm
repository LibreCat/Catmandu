package Catmandu::Cmd::fix_args;
use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Catmandu::Util qw(:is :check require_package);
require Catmandu::Fix::Has;

sub command {
    my ($self, $opts, $args) = @_;
    
    my $package = shift @$args;
    $package or die("no fix given\n");
    
    $package = $package =~ /^Catmandu::Fix::/o ? $package : "Catmandu::Fix::$package";

    say "package: '$package'";

    my $is_fix = $package->can("fix") || $package->can("emit");
    #$is_fix || die("package '$package' is not a Catmandu fix");

    require_package($package)->import;

    my $fix_args = Catmandu::Fix::Has->package_args_for($package);
    my $fix_opts = Catmandu::Fix::Has->package_opts_for($package);

    say "arguments:";
    say sprintf(" %s",$_->{key}) for @$fix_args;
    say "options:";
    say sprintf(" %s",$_->{key}) for @$fix_opts;

}

1;

=head1 NAME

    Catmandu::Cmd::fix_args  -  show arguments and options for a Catmandu Fix
=cut
