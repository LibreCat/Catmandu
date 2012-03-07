package Catmandu::Exporter::Template;

use Catmandu::Sane;
use Catmandu::Util qw(is_invocant);
use Moo;
use Template;

with 'Catmandu::Exporter';

my $XML_DECLARATION = qq(<?xml version="1.0" encoding="UTF-8"?>\n);

my $ADD_TT_EXT = sub {
    $_[0] =~ /\.tt$/ ? $_[0] : "$_[0].tt";
};

has xml             => (is => 'ro');
has template_before => (is => 'ro', coerce => $ADD_TT_EXT);
has template        => (is => 'ro', coerce => $ADD_TT_EXT, required => 1);
has template_after  => (is => 'ro', coerce => $ADD_TT_EXT);

$Template::Stash::PRIVATE = 0;

sub tt {
    state $tt = do {
        my $args = {
            ENCODING => 'utf8',
            ABSOLUTE => 1,
            ANYCASE  => 0,
        };

        if (is_invocant('Dancer')) {
            eval {
                $args->{INCLUDE_PATH} = Dancer::setting('views');
                $args->{VARIABLES} = {
                    settings => Dancer::Config->settings,
                };
            };
        }

        Template->new($args);
    };
}

sub add {
    my ($self, $data) = @_;
    if ($self->count == 0) {
        $self->fh->print($XML_DECLARATION) if $self->xml;
        $self->tt->process($self->template_before, {}, $self->fh) if $self->template_before;
    }
    $self->tt->process($self->template, $data, $self->fh);
}

sub commit {
    my ($self) = @_;
    $self->tt->process($self->template_after, {}, $self->fh) if $self->template_after;
}

=head1 NAME

Catmandu::Exporter::Template - a TT2 Template exporter

=head1 SYNOPSIS

    use Catmandu::Exporter::Template;

    my $exporter = Catmandu::Exporter::Template->new(
				fix => 'myfix.txt'
				xml => 1,
				template_before => '<path>/header.xml' ,
				template => '<path>/record.xml' ,
				template_after => '<path>/footer.xml' ,
		   );

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    $exporter->commit; # trigger the template_after

    printf "exported %d objects\n" , $exporter->count;

=head1 METHODS

=head2 new(xml => 0|1 , template_before => PATH, template => PATH , template_after => PATH)

Catmandu::Exporter::Template can be used to export data objects using Template Toolkit. The only 
required argument is 'template' which points to a file to render for each exported object. Set the
'template_before' and 'template_before' to add output at the start and end of the export. Optionally
provide an 'xml' indicator to include a XML header. 

=head2 commit

Commit all changes and execute the template_after if given.

=head1 SEE ALSO

L<Catmandu::Exporter>, L<Template>

=cut

1;
