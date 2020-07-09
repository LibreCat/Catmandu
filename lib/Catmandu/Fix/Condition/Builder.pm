package Catmandu::Fix::Condition::Builder;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Clone qw(clone);
use Moo::Role;
use namespace::clean;

with 'Catmandu::Fix::Base';

has pass_fixes => (is => 'rw', default => sub {[]});
has fail_fixes => (is => 'rw', default => sub {[]});
has tester     => (is => 'lazy');

sub emit {
    my ($self, $fixer) = @_;
    my $sub_var = $fixer->capture($self->tester);
    $self->_emit_branch(
        $self->_emit_call($sub_var, $fixer->var),
        $fixer->emit_fixes($self->pass_fixes),
        $fixer->emit_fixes($self->fail_fixes),
    );
}

sub import {
    my $target = caller;
    my ($fix, %opts) = @_;

    if (my $sym = $opts{as}) {
        my $sub = sub {
            my $data = shift;
            if ($opts{clone}) {
                $data = clone($data);
            }
            $fix->new(@_)->tester->($data);
        };
        no strict 'refs';
        *{"${target}::$sym"} = $sub;
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::Builder - Helper role to easily write fix conditions

=cut
