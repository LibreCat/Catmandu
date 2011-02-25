package Catmandu::Exporter::Benchmark;
# ABSTRACT: This package doesn't do any exporting actually but reports the speed
# of records presented to it
# VERSION
use Moose;
use JSON ();
use Time::HiRes qw(gettimeofday tv_interval);

has 't0' => (
    is => 'rw',
    default => sub {
            [gettimeofday]
    },
);

has 'cnt' => (
    is => 'rw' ,
    isa => 'Int',
    default => 0
);

has 'max' => (
    is => 'rw' ,
    isa => 'Int' ,
    default => 1000,
);

with qw(
    Catmandu::FileWriter
    Catmandu::Exporter
);

sub dump {
    my ($self, $obj) = @_;

    if (blessed $obj and $obj->can('each')) {
        $obj->each(sub {
            $self->cnt($self->cnt + 1);

            if ($self->cnt % $self->max == 0) {
                my $elapsed = tv_interval($self->t0);
                printf STDERR "time: %-3.3f : speed: %d objs/sec\n" , $elapsed , $self->max/$elapsed;
                $self->t0([gettimeofday]);
            }
        });
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 NAME

Catmandu::Exporter::Benchmark - a dummy Exporter to report conversion speeds

=head1 SYNOPSIS

    use Catmandu::Exporter::Benchmark;

    # Benchmark an import file
    catmandu convert -I Aleph -i map=data/aleph.map -O Benchmark import.txt

    # Benchmark a Simple store
    catmandu export -O Benchmark data/aleph.db

=head1 SEE ALSO

L<Catmandu::Exporter>
