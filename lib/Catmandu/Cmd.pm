package Catmandu::Cmd;
use Catmandu::Sane;
use parent qw(App::Cmd::Command);

# Internal required by App::Cmd
sub opt_spec {
    my ($class, $cli) = @_;
    (
        ['help|h|?', "print this usage screen"],
        $cli->global_opt_spec,
        $class->command_opt_spec($cli),
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

# These should be implemented by the Catmandu::Cmd's
sub description {}
sub command_opt_spec {}
sub command {}

=head1 NAME

Catmandu::Cmd - A base class for extending the Catmandu command line

=head1 SYNOPSIS

 # To create
 $ catmandu hello_world

 # You need:
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

 1;

=head1 DESCRIPTION

Catmandu:Cmd is a base class to extend the commands that can be provided for the 'catmandu' command line tools.
New catmandu commands should be defined in the Catmandu::Cmd namespace and extend Catmandu::Cmd.

Every command needs to implement 4 things:

 * command_opt_spec - which should return an array of command options with documentation
 * description - a long description of the command
 * command - the body which is executed 
 * head1 NAME - a short description of the command

=head1 METHODS

=head2 command_opt_spec() 

This method should be overridden to provide option specifications. (This is list of arguments passed to describe_options from Getopt::Long::Descriptive, after the first.)

If not overridden, it returns an empty list.

=head2 descripton()

This method should return a string containing the long documentation of the command

=head2 command()

This method does whatever it is the command should do! It is passed a hash reference of the parsed command-line options and an array reference of left over arguments.

=head1 DOCUMENTATION

At least provide for every command a NAME documentation

=head1 SEE ALSO

L<Catmandu::Cmd::config> , L<Catmandu::Cmd::convert> , L<Catmandu::Cmd::count> ,
L<Catmandu::Cmd::data> , L<Catmandu::Cmd::delete> , L<Catmandu::Cmd::export>,
L<Catmandu::Cmd::import> , L<Catmandu::Cmd::move>

=cut

1;
