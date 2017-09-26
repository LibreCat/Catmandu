package Catmandu::Cmd::touch;

use Catmandu::Sane;

our $VERSION = '1.0606';

use parent 'Catmandu::Cmd';
use Catmandu;
use namespace::clean;

sub command_opt_spec {
    (["key|field=s", "", {required => 1}], ["format=s", ""],);
}

sub command {
    my ($self, $opts, $args) = @_;

    my ($from_args, $from_opts) = $self->_parse_options($args);

    my $from_bag = delete $from_opts->{bag};
    my $from = Catmandu->store($from_args->[0], $from_opts)->bag($from_bag);

    $from->touch($opts->key, $opts->format);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::touch - add the current datetime to the objects in a bag

=head1 EXAMPLES

  catmandu touch <STORE> <OPTIONS>

  catmandu touch MongoDB --index-name shop --bag products --field date_updated

=cut
