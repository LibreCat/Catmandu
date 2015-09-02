package Catmandu::Fix::Bind::importer;

use Moo;
use Catmandu::Util qw(:is);
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Bind';

has importer_name => (fix_arg => 1);
has importer_args => (fix_opt => 'collect');

has importer      => (is => 'lazy', init_arg => undef);
has has_run       => (is => 'rw'  , default => sub { 0 });

sub _build_importer {
    my ($self) = @_;
    Catmandu->importer($self->importer_name, %{$self->importer_args});
}

sub unit {
    my ($self,$data) = @_;

    $data;
}

sub bind {
    my ($self,$mvar,$func,$name,$fixer) = @_;

    return if $self->has_run;

    $self->importer->each(sub {
        $fixer->fix($_[0]);
    });

    $self->has_run(1);

    $mvar;
}

=head1 NAME

Catmandu::Fix::Bind::importer - a binder runs fixes on records from an importer

=head1 SYNOPSIS

    # 
    catmandu run myfix.fix

    # with myfix.fix
    do importer(OAI,url: "http://lib.ugent.be/oai") 
      retain(_id)
      add_to_exporter(.,YAML)
    end

=head1 DESCRIPTION

The import binder computes all the Fix function on records read from the given importer.
This importer doesn't change the current importer to the given one! Use the 'catmandu run'
command line command to control importers solely by the Fix script. 

=head1 SEE ALSO

L<Catmandu::Fix::Bind>, 
L<Catmandu::Cmd::run>

=cut

1;
