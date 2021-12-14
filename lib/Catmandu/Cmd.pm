package Catmandu::Cmd;

use Catmandu::Sane;

our $VERSION = '1.2016';

use parent qw(App::Cmd::Command);
use Catmandu::Util qw(is_array_ref pod_section);
use Catmandu::Fix;
use Encode qw(decode);
use Log::Any ();
use namespace::clean;

sub log {
    Log::Any->get_logger(category => ref($_[0]));
}

# Internal required by App::Cmd;
sub prepare {
    my ($self, $app, @args) = @_;

    # not always available
    eval {
        require I18N::Langinfo;
        I18N::Langinfo->import(qw(langinfo CODESET));
        my $codeset = langinfo(CODESET());
        @args = map {decode $codeset, $_} @args;
    };
    $self->SUPER::prepare($app, @args);
}

# Internal required by App::Cmd
sub opt_spec {
    my ($class, $cli) = @_;
    (
        ['help|h|?', "print this usage screen"],
        $cli->global_opt_spec, $class->command_opt_spec($cli),
    );
}

# Internal required by App::Cmd
sub execute {
    my ($self, $opts, $args) = @_;

    if ($opts->{version}) {
        print $Catmandu::VERSION;
        exit;
    }
    if ($opts->{help}) {
        print $self->usage->text;
        exit;
    }

    $self->command($opts, $args);
}

# show examples, if available in POD
sub description {
    my $class = ref shift;

    my $s = pod_section($class, "name");
    $s =~ s/.*\s+-\s+//;
    $s = ucfirst($s);
    $s .= "\n";

    for (pod_section($class, "examples")) {
        $s .= "Examples:\n\n$_";
    }

    "$s\nOptions:";
}

# These should be implemented by the Catmandu::Cmd's
sub command_opt_spec { }
sub command          { }

# helpers
sub _parse_options {
    my ($self, $args, %opts) = @_;

    $opts{separator} //= 'to';

    my $a        = my $lft_args = [];
    my $o        = my $lft_opts = {};
    my $rgt_args = [];
    my $rgt_opts = {};

    for (my $i = 0; $i < @$args; $i++) {
        my $arg = $args->[$i];
        if ($arg eq $opts{separator}) {
            $a = $rgt_args;
            $o = $rgt_opts;
        }
        elsif ($arg =~ s/^-+//) {
            $arg =~ s/-/_/g;
            if (exists $o->{$arg}) {
                if (is_array_ref($o->{$arg})) {
                    push @{$o->{$arg}}, $args->[++$i];
                }
                else {
                    $o->{$arg} = [$o->{$arg}, $args->[++$i]];
                }
            }
            else {
                $o->{$arg} = $args->[++$i];
            }
        }
        else {
            push @$a, $arg;
        }
    }

    return $lft_args, $lft_opts, $rgt_args, $rgt_opts;
}

sub _build_fixer {
    my ($self, $opts) = @_;
    if ($opts->var) {
        return Catmandu::Fix->new(
            preprocess => 1,
            fixes      => $opts->fix,
            variables  => $opts->var,
        );
    }
    Catmandu::Fix->new(
        preprocess => $opts->preprocess ? 1 : 0,
        fixes      => $opts->fix,
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd - A base class for extending the Catmandu command line

=head1 SYNOPSIS

  # to create a command:
  $ catmandu hello_world

  # you need a package:
  package Catmandu::Cmd::hello_world;
  use parent 'Catmandu::Cmd';

  sub command_opt_spec {
     (
         [ "greeting|g=s", "provide a greeting text" ],
     );
  }

  sub description {
     <<EOS;
  examples:

  catmandu hello_world --greeting "Hoi"

  options:
  EOS
  }

  sub command {
     my ($self, $opts, $args) = @_;
     my $greeting = $opts->greeting // 'Hello';
     print "$greeting, World!\n"
  }

  =head1 NAME

  Catmandu::Cmd::hello_world - prints a funny line

  =cut



=head1 DESCRIPTION

Catmandu:Cmd is a base class to extend the commands that can be provided for
the 'catmandu' command line tools.  New catmandu commands should be defined in
the Catmandu::Cmd namespace and extend Catmandu::Cmd.

Every command needs to implement 4 things:

  * command_opt_spec - which should return an array of command options with documentation
  * description - a long description of the command
  * command - the body which is executed
  * head1 NAME - a short description of the command

=head1 METHODS

=head2 log()

Access to the logger

=head2 command_opt_spec()

This method should be overridden to provide option specifications. (This is list of arguments passed to describe_options from Getopt::Long::Descriptive, after the first.)

If not overridden, it returns an empty list.

=head2 description()

This method should return a string containing the long documentation of the command

=head2 command()

This method does whatever it is the command should do! It is passed a hash reference of the parsed command-line options and an array reference of left over arguments.

=head1 DOCUMENTATION

At least provide for every command a NAME documentation

=head1 SEE ALSO

L<Catmandu::Cmd::config> , L<Catmandu::Cmd::convert> , L<Catmandu::Cmd::count> ,
L<Catmandu::Cmd::data> , L<Catmandu::Cmd::delete> , L<Catmandu::Cmd::export>,
L<Catmandu::Cmd::import> , L<Catmandu::Cmd::move> , L<Catmandu::Cmd::run>

=cut
