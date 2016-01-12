package Catmandu::Cmd::drop;

use Catmandu::Sane;

our $VERSION = '0.9505';

use parent 'Catmandu::Cmd';
use Catmandu;
use namespace::clean;

sub command_opt_spec {
    (
        [ "bag=s", "drop a bag" ],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    my ($from_args, $from_opts) = $self->_parse_options($args);

    my $from = Catmandu->store($from_args->[0], $from_opts);
    if ($opts->bag) {
        $from->bag($opts->bag)->drop;
    } else {
        $from->drop;
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::drop - drop a store or one of it's bags

=head1 EXAMPLES

  catmandu drop <STORE> <OPTIONS>

  # drop the whole store
  catmandu drop ElasticSearch --index-name items
  # drop a single bag
  catmandu drop ElasticSearch --index-name items --bag thingies

=cut
