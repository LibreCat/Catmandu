package Catmandu::Exporter::Template;
use Catmandu::Sane;
use Catmandu::Util qw(io quacks);
use Template;
use Catmandu::Object
    file => { default => sub { *STDOUT } },
    view => 'r',
    xml  => 'r';

$Template::Stash::PRIVATE = 0;

sub template_name {
    my $name = $_[0];
    $name = "$name.tt" if $name !~ /\.tt$/;
    $name;
}

sub add {
    my ($self, $obj) = @_;

    my $file = io($self->file, 'w');

    my $view = template_name($self->view);

    my $tmpl_opts = {
        ENCODING => 'utf8',
        ABSOLUTE => 1,
        ANYCASE  => 0,
    };

    if ($ENV{DANCER_APPDIR}) {
        require Dancer;
        $tmpl_opts->{INCLUDE_PATH} = Dancer::setting('views');
        $tmpl_opts->{VARIABLES} = {
            settings => Dancer::Config->settings,
        };
    }

    my $tmpl = Template->new($tmpl_opts);

    if ($self->xml) {
        print $file qq(<?xml version="1.0" encoding="UTF-8"?>\n);
    }

    if (quacks $obj, 'each') {
        return $obj->each(sub {
            $tmpl->process($view, $_[0], $file);
        });
    }

    $tmpl->process($view, $obj, $file);
    1;
}

1;
