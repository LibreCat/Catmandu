package Catmandu::Cmd::count;

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

catmandu count ElasticSearch --index-name shop --bag products --query 'brand:Acme'

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
        $from = $from->searcher(query => $opts->query);
    }

    say $from->count;
}

1;

=head1 NAME

Catmandu::Cmd::count - count the number of objects in a store


