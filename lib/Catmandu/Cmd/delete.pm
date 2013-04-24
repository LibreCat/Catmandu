package Catmandu::Cmd::delete;

use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Catmandu;
use Catmandu::Fix;

sub command_opt_spec {
    (
        [ "query|q=s", "" ],
    );
}

sub description {
    <<EOS;
examples:

catmandu delete ElasticSearch --index-name items --bag book -q 'title:"My Rabbit"'

options:
EOS
}

sub command {
    my ($self, $opts, $args) = @_;

    my $from_args = [];
    my $from_opts = {};

    for (my $i = 0; $i < @$args; $i++) {
        my $arg = $args->[$i];
        if ($arg =~ s/^-+//) {
            $arg =~ s/-/_/g;
            $from_opts->{$arg} = $args->[++$i];
        } else {
            push @$from_args, $arg;
        }
    }

    my $from_bag = delete $from_opts->{bag};
    my $from = Catmandu->store($from_args->[0], $from_opts)->bag($from_bag);
    if (defined $opts->query) {
        $from->delete_by_query(query => $opts->query);
    } else {
        $from->delete_all;
    }

    $from->commit;
}

1;

=head1 NAME

Catmandu::Cmd::delete - delete objects from a store
