use MooseX::Declare;

class Catmandu::Cmd::Command extends MooseX::App::Cmd::Command
    with MooseX::Getopt::Dashes {
    use 5.010;
    use Catmandu qw(project);
    use Path::Class;

    has home => (
        traits => ['Getopt'],
        is => 'rw',
        isa => 'Str',
        cmd_aliases => 'H',
        documentation => "The project home directory. Defaults to the current directory.",
    );

    has env => (
        traits => ['Getopt'],
        is => 'rw',
        isa => 'Str',
        cmd_aliases => 'E',
        default => 'development',
        documentation => "The project environment. Defaults to development.",
    );

    method BUILD {
        print $self->help_text and exit if $self->help_flag;

        if ($self->home) {
            $self->home(dir($self->home)->absolute->resolve->stringify);
        } else {
            $self->home(dir->absolute->stringify);
        }

        project(home => $self->home,
                env  => $self->env);

        unshift(@INC, project->lib);
    }

    method help_text {
        $self->usage->leader_text . "\n" .
        $self->usage->option_text;
    }
}

role Catmandu::Cmd::Opts::Verbose {
    has verbose => (
        traits => ['Getopt'],
        is => 'rw',
        isa => 'Bool',
        cmd_aliases => 'v',
        documentation => "Verbose output.",
    );
}

role Catmandu::Cmd::Opts::Exporter {
    has exporter => (
        traits => ['Getopt'],
        is => 'rw',
        isa => 'Str',
        lazy => 1,
        cmd_aliases => 'O',
        default => 'JSON',
        documentation => "The Catmandu::Exporter class to use. Defaults to JSON.",
    );

    has exporter_arg => (
        traits => ['Getopt'],
        is => 'rw',
        isa => 'HashRef',
        lazy => 1,
        cmd_aliases => 'o',
        default => sub { +{} },
        predicate => 'has_exporter_arg',
        documentation => "Pass params to the exporter constructor.",
    );
}

role Catmandu::Cmd::Opts::Importer {
    has importer => (
        traits => ['Getopt'],
        is => 'rw',
        isa => 'Str',
        lazy => 1,
        cmd_aliases => 'I',
        default => 'JSON',
        documentation => "The Catmandu::Importer class to use. Defaults to JSON.",
    );

    has importer_arg => (
        traits => ['Getopt'],
        is => 'rw',
        isa => 'HashRef',
        lazy => 1,
        cmd_aliases => 'i',
        default => sub { +{} },
        predicate => 'has_importer_arg',
        documentation => "Pass params to the importer constructor.",
    );
}

role Catmandu::Cmd::Opts::Index {
    has index => (
        traits => ['Getopt'],
        is => 'rw',
        isa => 'Str',
        lazy => 1,
        cmd_aliases => 'T',
        default => 'Simple',
        documentation => "The Catmandu::Index class to use. Defaults to Simple.",
    );

    has index_arg => (
        traits => ['Getopt'],
        is => 'rw',
        isa => 'HashRef',
        lazy => 1,
        cmd_aliases => 't',
        default => sub { +{} },
        documentation => "Pass params to the index constructor.",
    );
}

role Catmandu::Cmd::Opts::Store {
    has store => (
        traits => ['Getopt'],
        is => 'rw',
        isa => 'Str',
        lazy => 1,
        cmd_aliases => 'S',
        default => 'Simple',
        documentation => "The Catmandu::Store class to use. Defaults to Simple.",
    );

    has store_arg => (
        traits => ['Getopt'],
        is => 'rw',
        isa => 'HashRef',
        lazy => 1,
        cmd_aliases => 's',
        default => sub { +{} },
        predicate => 'has_store_arg',
        documentation => "Pass params to the store constructor.",
    );
}

1;

