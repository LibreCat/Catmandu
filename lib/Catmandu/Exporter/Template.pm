package Catmandu::Exporter::Template;
use Catmandu::Sane;
use Catmandu::Util qw(io quack);
use Dancer qw(:syntax template);
use Catmandu::Object file => { default => sub { *STDOUT } }, view => 'r';

sub add {
    my ($self, $obj) = @_;

    my $file = io $self->file, 'w';
    my $view = $self->view;

    if (quack $obj, 'each') {
        return $obj->each(sub {
            print $file, template($view, $_[0]);
        });
    }

    print $file, template($view, $obj);
    1;
}

1;
