package Catmandu::Interactive;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Catmandu;
use Moo;
use namespace::clean;

has in => (
    is      => 'ro',
    default => sub {
        Catmandu::Util::io(\*STDIN);
    }
);

has out => (
    is      => 'ro',
    default => sub {
        Catmandu::Util::io(
            \*STDOUT,
            mode    => 'w',
            binmode => ':encoding(utf-8)'
        );
    }
);

has silent => (is => 'ro');

has exporter => (is => 'ro', default => sub {'YAML'});

has exporter_args => (is => 'ro', default => sub {+{}});

has header => (
    is      => 'ro',
    default => sub {
        "\e[36m\n"
            . "      A_A    ____      _                             _             \n"
            . "     (-.-)  / ___|__ _| |_ _ __ ___   __ _ _ __   __| |_   _       \n"
            . "      |-|  | |   / _` | __| '_ ` _ \\ / _` | '_ \\ / _` | | | |    \n"
            . "     /   \\ | |__| (_| | |_| | | | | | (_| | | | | (_| | |_| |     \n"
            . "    |     | \\____\\__,_|\\__|_| |_| |_|\\__,_|_| |_|\\__,_|\\__,_|\n"
            . "    |  || |  |  \\___            version: $Catmandu::VERSION       \n"
            . "     \\_||_/_/                                                \e[0m\n"
            . "                                                                   \n"
            . "Commands:                     | Interactive support is still       \n"
            . " \\h - the fix history         | experimental. Run:                \n"
            . " \\r - repeat the previous fix | \$ catmandu run <your_fix_script> \n"
            . " \\q - quit                    | to access all Catmandu features   \n";
    }
);

has data => (is => 'rw', default => sub {+{}});

has _history => (is => 'ro', default => sub {[]});

sub run {
    my $self = shift;

    my $keep_reading = 0;
    my $buffer       = '';

    $self->head;

    $self->prompt;

    while (my $line = $self->in->getline) {
        if ($line =~ /^\\(.*)/) {
            next if length $buffer;

            my ($command, $args) = split(/\s+/, $1, 2);

            if ($command eq 'h') {
                $self->cmd_history;
                $self->prompt('fix');
                next;
            }
            elsif ($command eq 'r') {
                if (@{$self->_history} > 0) {
                    $line = $self->_history->[-1];
                }
                else {
                    $self->prompt('fix');
                    next;
                }
            }
            elsif ($command eq 'q') {
                last;
            }
            else {
                $self->error("unknown command $command");
                $self->prompt('fix');
                next;
            }
        }

        $line = "$buffer$line" if length $buffer;

        if (length $line) {
            my ($fixes, $keep_reading, $error)
                = $self->parse_fixes($line, $keep_reading);

            if ($error) {
                $buffer = '';
            }
            elsif ($keep_reading == 0) {
                my $fixer = Catmandu::Fix->new(fixes => $fixes);

                $self->data($fixer->fix($self->data));
                $self->export;

                push(@{$self->_history}, $line);

                $buffer = '';
            }
            else {
                $buffer = $line;
                $self->prompt('...');
                next;
            }
        }

        $self->prompt('fix');
    }
}

sub cmd_history {
    my ($self) = @_;

    $self->out->printf(join("", @{$self->_history}));
}

sub head {
    my ($self) = @_;

    $self->out->printf("%s\n", $self->header) unless $self->silent;
}

sub error {
    my ($self, $txt) = @_;
    $self->out->print("ERROR: $txt\n") unless $self->silent;
}

sub prompt {
    my ($self, $txt) = @_;
    $txt //= 'fix';

    $self->out->printf("\e[35m%s > \e[0m", $txt) unless $self->silent;
}

sub export {
    my ($self) = @_;
    my $exporter = Catmandu->exporter(
        $self->exporter,
        %{$self->exporter_args},
        fh => $self->out
    );
    $exporter->add($self->data);
    $exporter->commit;
}

sub parse_fixes {
    my ($self, $string, $keep_reading) = @_;

    my $parser = Catmandu::Fix::Parser->new;

    my $fixes;
    my $error = 0;

    try {
        $fixes        = $parser->parse($string);
        $keep_reading = 0;
    }
    catch {
        if (ref($_) eq 'Catmandu::FixParseError'
            && $_->message
            =~ /Can't use an undefined value as a SCALAR reference at/)
        {
            $keep_reading = 1;
        }
        else {
            $_ =~ s/\n.*//g;
            $self->error($_);
            $error = 1;
        }
    };

    return ($fixes, $keep_reading, $error);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Interactive - An interactive command line interpreter of the Fix language

=head1 SYNOPSIS

   # On the command line
   catmandu run

   # Or, in Perl
   use Catmandu::Interactive;
   use Getopt::Long;

   my $exporter = 'YAML';

   GetOptions("exporter=s" => \$exporter);

   my $app = Catmandu::Interactive->new(exporter => $exporter);

   $app->run();

=head1 DESCRIPTION

This module provide a simple interactive interface to the Catmandu Fix language.

=head1 CONFIGURATION

=over

=item in

Read input from an IO::Handle

=item out

Write output to an IO::Handle

=item silent

If set true, then no headers or prompts are printed

=item data

A hash containing the input record

=item exporter

The name of an exporter package

=item exporter_args

The options for the exporter

=back

=head1 METHODS

=head2 run

Run the interactive environment.

=head1 SEE ALSO

L<Catmandu>

=cut
