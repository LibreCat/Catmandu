package Catmandu::Cmd::Command::repl;

use namespace::autoclean;
use Moose;
use Devel::REPL;

extends qw(Catmandu::Cmd::Command);

sub execute {
    my ($self, $opts, $args) = @_;

    my $repl = Devel::REPL->new;

    $repl->load_plugin($_) for qw(Colors LexEnv MultiLine::PPI Completion
        CompletionDriver::LexEnv CompletionDriver::LexEnv
        CompletionDriver::Keywords CompletionDriver::INC
        CompletionDriver::Methods
        Packages FancyPrompt DDC);

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
    $repl->eval('use Catmandu -all');
    $repl->run;
}

__PACKAGE__->meta->make_immutable;

1;

