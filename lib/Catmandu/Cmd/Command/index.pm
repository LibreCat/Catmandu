package Catmandu::Cmd::Command::index;
# VERSION
use 5.010;
use Moose;
use MooseX::Types::IO qw(IO);
use File::Slurp qw(slurp);
use Catmandu::Util qw(load_class);
use JSON::Path;
use Time::HiRes qw(gettimeofday tv_interval);
use List::Flatten;

extends qw(Catmandu::Cmd::Command);

with qw(
    Catmandu::Cmd::Opts::Index
    Catmandu::Cmd::Opts::Store
    Catmandu::Cmd::Opts::Fix
    Catmandu::Cmd::Opts::Verbose
);

has map => (
    traits => ['Getopt'],
    is => 'rw',
    isa => IO,
    coerce => 1,
    predicate => 'has_map',
    documentation => "Path to the map definition file to use.",
);

has delkey => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    default => 'DEL',
    predicate => 'has_delkey',
    documentation => "If this key is available in the object, then the record should be deleted.",
);

sub execute {
    my ($self, $opts, $args) = @_;

    $self->store =~ /::/ or $self->store("Catmandu::Store::" . $self->store);
    $self->index =~ /::/ or $self->index("Catmandu::Index::" . $self->index);

    if (my $arg = shift @$args) {
        $self->map($arg);
    }

    load_class($self->index);
    load_class($self->store);

    my $index = $self->index->new($self->index_arg);
    my $store = $self->store->new($self->store_arg);

    if ($self->has_fix) {
        $store = $self->fixer->fix($store);
    }

    $self->msg("Indexing...");

    my $n = 0;
    my $delkey = $self->delkey;
    my $t0 = [gettimeofday];

    if ($self->has_map) {
        my %map = $self->file_map;
        $store->each(sub {
            my $obj = shift;
            my $doc = {};

            foreach my $key (keys %map) {
                foreach my $path (@{$map{$key}}) {
                    my @values = flat (JSON::Path->new($path)->values($obj));
                    my $val = join ' ', @values ? @values : ();

                    $doc->{$key} .= $val; 
                }
            }
            $self->msg(sprintf "$n %d rec/sec", $n/tv_interval($t0)) if $n % 100 == 0;

            exists $doc->{$delkey} ? $index->delete($doc) : $index->save($doc);

            $n++;
        });
    } else {
        $store->each(sub {
            my $doc = shift;
            $self->msg(sprintf "$n %d rec/sec", $n/tv_interval($t0)) if $n % 100 == 0;

            exists $doc->{$delkey} ? $index->delete($doc) : $index->save($doc);

            $n++;
        });
    }

    $self->msg(sprintf "=$n %d rec/sec", $n/tv_interval($t0));

    $self->msg("Committing...");

    $index->commit;

    $self->msg($n == 1 ? "Indexed 1 object" : "Indexed $n objects");
}

sub file_map {
    my $self = shift;

    return undef unless $self->map;

    my %map = ();

    foreach my $line (split /\n/, slurp($self->map)) {
        next if ($line =~ /^\s*#/);
        next if ($line =~ /^\s*$/);

        my ($path, $key) = split /\s+/, $line;
        push @{$map{$key}} , $path;
    }

    %map;
}

sub msg {
    my ($self, $text) = @_;
    local $| = 1;
    if ($self->verbose) {
        say $text;
    }
}

__PACKAGE__->meta->make_immutable;

no Moose;
no MooseX::Types::IO;
no File::Slurp;
no Catmandu::Util;

1;

=head1 NAME

Catmandu::Cmd::Command::index - index a store
