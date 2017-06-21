package Catmandu::Fix::Bind::importer;

use Catmandu::Sane;

our $VERSION = '1.0601';

use Moo;
use Catmandu::Util qw(:is);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Bind', 'Catmandu::Fix::Bind::Group';

has importer_name => (fix_arg => 1);
has step          => (fix_opt => 1);
has importer_args => (fix_opt => 'collect');

has importer => (is => 'lazy');

sub _build_importer {
    my ($self) = @_;
    Catmandu->importer($self->importer_name, %{$self->importer_args});
}

sub unit {
    my ($self, $data) = @_;
    $data;
}

sub bind {
    my ($self, $mvar, $code) = @_;

    if ($self->step) {
        my $next = $self->importer->next;
        $code->($next) if $next;
    }
    else {
        $self->importer->each(
            sub {
                $code->($_[0]);
            }
        );
    }

    $mvar;
}

1;

__END__

=pod

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

    # Or in an runnable Fix script:

    #!/usr/bin/env catmandu run
    add_field(hello,world)
    add_to_exporter(.,YAML)


    # Or:

    #!/usr/bin/env catmandu run
    do importer(OAI,url: "http://lib.ugent.be/oai")
      retain(_id)
      add_to_exporter(.,YAML)
    end


=head1 DESCRIPTION

The import binder computes all the Fix function on records read from the given importer.
This importer doesn't change the current importer to the given one! Use the 'catmandu run'
command line command to control importers solely by the Fix script.

=head1 CONFIGURATION

=head2 importer(IMPORTER_NAME, step: true|false, IMPORTER_ARGS...)

Load the import IMPORTER_NAME in the current context. When step is 'true' then for
every execution of do importer() only one item will be read from the importer. This
latter option can become handy in nested iterators:

    # This will produce:
    #  {"n":0}
    #  {"m":0}
    #  {"n":1}
    #  {"m":1}
    #  {"n":2}
    #  {"m":2}
    # ...
    do importer(Mock,size:20)
        move_field(n,brol)
        add_to_exporter(.,JSON)

        do importer(Mock,size:20,step:true)
            move_field(n,m)
            add_to_exporter(.,JSON)
        end
    end

=head1 SEE ALSO

L<Catmandu::Fix::Bind>,
L<Catmandu::Cmd::run>

=cut
