package Catmandu::Cmd::help;

use Catmandu::Sane;

our $VERSION = '1.2016';

use parent 'Catmandu::Cmd';
use App::Cmd::Command::help;
use Catmandu::Util qw(require_package pod_section);
use namespace::clean;

sub usage_desc {
    '%c help [ <command> | ( export | import | store | fix ) <name> ]';
}

sub command_names {qw/help --help -h -?/}

my %MODULES = (
    Exporter => {
        re    => qr/^export(er)?$/i,
        usage => [
            "catmandu convert ... to %n [options]",
            "catmandu export  ... to %n [options]",
        ],
    },
    Importer => {
        re    => qr/^import(er)?$/i,
        usage => [
            "catmandu convert %n [options] to ...",
            "catmandu import  %n [options] to ...",
        ],
    },
    Store => {
        re    => qr/^(store|copy)$/i,
        usage => [
            "catmandu import ... to %n [options]",
            "catmandu copy   ... to %n [options]",
            "catmandu export %n [options] ...",
            "catmandu copy   %n [options] ...",
        ]
    },
    Fix         => {re => qr/^fix$/i, usage => ["%n( [options] )"]},
    'Fix::Bind' =>
        {re => qr/^bind$/i, usage => ["do %n( [options] ) ... end"]},
    'Fix::Condition' =>
        {re => qr/^condition$/i, usage => ["if %n( [options] ) ... end"]},
);

sub execute {
    my ($self, $opts, $args) = @_;

    # TODO: list available Importer/Exporters/Stores/Fixes...

    if (@$args == 2) {

        # detect many forms such as:
        # export JSON, exporter JSON, JSON export, JSON exporter
        foreach (0, 1) {
            foreach my $type (keys %MODULES) {
                if ($args->[$_] =~ $MODULES{$type}->{re}) {
                    $self->help_about($type, $args->[($_ + 1) % 2]);
                    return;
                }
            }
        }
    }
    elsif (@$args == 1 && $args->[0] =~ qr/^fix(es)?$/) {
        $self->help_fixes;
        return;
    }

    App::Cmd::Command::help::execute(@_);
}

sub help_about {
    my ($self, $type, $name) = @_;

    my $class;
    if ($type eq 'Fix') {
        foreach ('Fix', 'Fix::Bind', 'Fix::Condition') {
            $type = $_;
            try {
                require_package($name, "Catmandu::$type");
                $class = "Catmandu::${type}::$name";
            }
            catch { };
            last if $class;
        }
        unless ($class) {
            Catmandu::NoSuchFixPackage->throw(
                {
                    message      => "No such fix package: $name",
                    package_name =>
                        "Catmandu::Fix::(Bind::|Condition::)?$name",
                    fix_name => $name,
                }
            );
        }
    }

    $class = "Catmandu::${type}::$name";
    require_package($class);

    my $about = pod_section($class, "name");
    $about =~ s/\n/ /mg;
    say ucfirst($about);

    say "\nUsage:";
    print join "", map {s/%n/$name/g; "  $_\n"} @{$MODULES{$type}->{usage}};

    my $descr = pod_section($class, "description");
    chomp $descr;
    say "\n$descr" if $descr;

    # TODO: include examples?

    my $options = pod_section($class, "configuration");
    if ($options) {
        $options =~ s/^([a-z0-9_-]+)\s*\n?/--$1, /mgi;
        $options
            =~ s/^(--[a-z0-9_-]+(,\s*--[a-z0-9_-]+)*),\s*([^-])/" $1\n    $3"/emgi;
        print "\nOptions:\n$options";
    }
}

sub help_fixes {
    my ($self) = @_;

    my $fixes = Catmandu->importer(
        'Modules',
        namespace => 'Catmandu::Fix',
        primary   => 1
    )->select(name => qr/::[a-z][^:]*$/)->map(
        sub {
            $_[0]->{name} =~ s/.*:://;
            $_[0];
        }
    );

    my $len = $fixes->max(sub {length $_[0]->{name}});
    $fixes->sorted('name')->each(
        sub {
            say sprintf "%-${len}s %s", $_[0]->{name}, $_[0]->{about};
        }
    );

    say "\nGet additional help with: catmandu help fix <NAME>";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::help - show help

=head1 EXAMPLES

  catmandu help convert
  catmandu help import JSON
  catmandu help help
  catmandu help fix set_field

=cut
