package Catmandu::Cmd::fix_args;
use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Catmandu::Util qw(:is :check require_package);

sub command {
    my ($self, $opts, $args) = @_;
    
    my $package = shift @$args;
    $package or die("no fix given\n");

    my $name = $package;
    $name =~ s/^Catmandu::Fix:://o;
    
    $package = $package =~ /^Catmandu::Fix::/o ? $package : "Catmandu::Fix::$package";

    require_package($package);

    my $is_fix = $package->can("fix") || $package->can("emit");
    $is_fix || die("package '$package' is not a Catmandu fix");

    $package->import;

    $package->can("package_args") or die("package has no method package_args");
    $package->can("package_opts") or die("package has no method package_ops");

    my $fix_args = $package->package_args();
    my $fix_opts = $package->package_opts();

    my @parts;

    push @parts,"<".$_->{key}.">" for @$fix_args;
    push @parts,$_->{key}." => <".$_->{key}.">" for grep { !($_->{collect}) } @$fix_opts;
    push @parts,"[<options for ".$_->{key}.">]" for grep { $_->{collect} } @$fix_opts;

    my $doc = "$name(".join(',',@parts).")";
    say $doc;

}

1;

=head1 NAME

Catmandu::Cmd::fix_args - show arguments and options for a Catmandu Fix

=head1 USAGE

    catmandu fix_args copy_field
    => copy_field(<old_path>,<new_path>)

=head1 NOTES

    This commands can only list arguments and options for those fixes that make use of L<Catmandu::Fix::Has>

=head1 AUTHOR

    Nicolas Franck, C<< <nicolas.franck at ugent.be> >>
    
=cut
