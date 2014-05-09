package CatmanduLocalFixes;
use Catmandu::Sane;
use Module::Pluggable search_path => ["Catmandu::Fix"],search_dirs => [@INC];

sub new {
    bless {},$_[0];
}

package Catmandu::Cmd::fixes;
use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Catmandu::Util qw(:is);
use Module::Info;

sub command_opt_spec {
    (
        ["local|l!","list local packages",{ default => 1 }],
        ["verbose|v","include package information"],
        ["csv","output in csv format"]

    );
}
sub print_simple {
    my($mods,%opts)=@_;

    for my $mod(@$mods){
        print $mod->{name};
        
        if($opts{verbose}){
            print ", file: ".$mod->{file};
            if(is_string($mod->{version})){
                print ", version: ".$mod->{version};
            }
        }

        say "";
    }

}
sub print_csv {
    require Catmandu::Exporter::CSV;

    my($mods,%opts) = @_;

    my @fields = qw(name);
    push @fields,qw(version file) if $opts{verbose};

    my $exporter = Catmandu::Exporter::CSV->new(fields => \@fields);
    $exporter->add_many($mods);
    $exporter->commit;
}

sub command {
    my ($self, $opts, $args) = @_;

    my @local_packages;

    if($opts->local){
        
        push @local_packages,grep {

            #filter real fixes
            my(@parts)= split ':',$_;
            $parts[-1] =~ /^[a-z][0-9a-z_]+$/o;

        } CatmanduLocalFixes->new()->plugins();
        
    }

    my @modules;
    for my $package(@local_packages){

        #reason for this: previous step return first found package, not all installed versions
        push @modules,Module::Info->all_installed($package,@INC);

    }


    @modules = map { 
        +{
            name => $_->name,
            file => $_->file,
            version => $_->version
        } 
    } @modules;

    if($opts->csv){
        print_csv(\@modules,verbose => $opts->verbose);
    }else{
        print_simple(\@modules,verbose => $opts->verbose);
    }

}

1;

=head1 NAME

    Catmandu::Cmd::fixes  -  list available Catmandu fixes

=cut
