package Catmandu::Cmd::run;

use Catmandu::Sane;

our $VERSION = '1.0603';

use parent 'Catmandu::Cmd';
use Catmandu;
use Catmandu::Util qw(require_package);
use namespace::clean;

sub command_opt_spec {
    (
        ["var=s%",        ""],
        ["fix=s@",        ""],
        ["preprocess|pp", ""],
        ["verbose|v",     ""],
        ["i",             "interactive mode"],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    if (defined $opts->{i} || !defined $args->[0]) {
        my $pkg = require_package('Catmandu::Interactive');
        my $app = Catmandu::Interactive->new();
        $app->run();
    }
    else {
        my $fix_file = $args->[0];
        $fix_file = [\*STDIN] unless defined $fix_file;

        $opts->{fix} = [$fix_file];

        my $from = Catmandu->importer('Null');
        $from = $self->_build_fixer($opts)->fix($from);

        if ($opts->verbose) {
            $from = $from->benchmark;
        }

        my $into = Catmandu->exporter('Null');
        my $n    = $into->add_many($from);
        $into->commit;

        if ($opts->verbose) {
            say STDERR $n == 1
                ? "converted 1 object"
                : "converted $n objects";
            say STDERR "done";
        }
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::run - run a fix command

=head1 EXAMPLES
   
  # Run an interactive Fix shell
  $ catmandu run

  # Execute the fix script
  $ catmandu run myfixes.txt

  # Execute the scripts with options passed
  $ catmandu run --var source=bla myfixes.txt
  $ cat myfixes.txt
  add_field(my_source,{{source}})

  # Or create an execurable fix script:

  #!/usr/bin/env catmandu run
  do importer(Mock,size:10)
    add_field(foo,bar)
    add_to_exporter(.,JSON)
  end

=cut
