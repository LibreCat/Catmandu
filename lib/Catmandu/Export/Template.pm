package Catmandu::Export::Template;
use Catmandu::Util qw(io is_able);
use Catmandu::Class qw(file template);

sub build {
    my ($self, $args) = @_;
    $self->{file} = $args->{file} || *STDOUT;
    $self->{template} = $args->{template} || confess("Attribute template is required");
}

sub default_attribute {}

sub dump {
    my ($self, $obj) = @_;

    my $file = io $self->file, 'w';
    my $template = $self->template;

    my $n;

    if (ref $obj eq 'HASH') {
        Catmandu->render($template, $obj, $file);
        $n = 1;
    } elsif (ref $obj eq 'ARRAY') {
        foreach (@$obj) {
            Catmandu->render($template, $_, $file);
        }
        $n = @$obj;
    } elsif (is_able($obj, 'each')) {
        $n = $obj->each(sub { Catmandu->render($template, $_[0], $file) });
    } else {
        confess "Invalid object";
    }

    $n;
}

no Catmandu::Util;
1;
