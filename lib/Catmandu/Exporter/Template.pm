package Catmandu::Exporter::Template;
use Catmandu::Sane;
use Catmandu::Util qw(io quack);
use Catmandu::Object file => { default => sub { *STDOUT } }, view => 'r';
use Template;

$Template::Stash::PRIVATE = 0;

sub add {
    my ($self, $obj) = @_;

    my $file = io $self->file, 'w';
    my $view = $self->view;
    my $tmpl = Template->new({
            ENCODING => 'utf8',
            ABSOLUTE => 1,
    });

    if ($view !~ /\.tt$/) {
        $view = "$view.tt";
    }

    if (quack $obj, 'each') {
        return $obj->each(sub {
            $tmpl->process($view, $_[0], $file);
        });
    }

    $tmpl->process($view, $obj, $file);
    1;
}

1;
