package Catmandu::Cmd::Console;

use Any::Moose;
use Devel::REPL;

with any_moose('X::Getopt');

sub run {
    my $self = shift;
    my $repl = Devel::REPL->new;

    my @plugins = qw(Colors LexEnv MultiLine::PPI Completion
        CompletionDriver::LexEnv CompletionDriver::LexEnv
        CompletionDriver::Keywords CompletionDriver::INC
        CompletionDriver::Methods
        Packages FancyPrompt DDC);

    my $perl = <<"PERL";
use Catmandu;
use lib Catmandu->lib;
PERL

    foreach my $plugin (@plugins) {
        $repl->load_plugin($plugin);
    }

    $repl->fancy_prompt(sub {
        my $self  = shift;
        my $pkg   = $self->can('current_package') ? $self->current_package : 'main';
        my $depth = $self->can('line_depth') ? $self->line_depth : '';
        sprintf '%s:%03d:%s> ',
            $pkg,
            $self->lines_read,
            $depth;
    });

    $repl->fancy_continuation_prompt(sub {
        my $self  = shift;
        my $pkg   = $self->can('current_package') ? $self->current_package : 'main';
        my $depth = $self->can('line_depth') ? $self->line_depth : '';
        sprintf '%s:%03d:%s* ',
            $pkg,
            $self->lines_read,
            $depth;
    });

    $repl->current_package('main');
    $repl->lexical_environment->do($perl);
    $repl->run;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
__PACKAGE__;

