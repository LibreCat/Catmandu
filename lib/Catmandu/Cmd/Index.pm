package Catmandu::Cmd::Index;

use 5.010;
use Moose;
use MooseX::Types::IO::All 'IO_All';
use Plack::Util;
use Catmandu;
use JSON::Path;
use lib Catmandu->lib;

with 'Catmandu::Command';

has store => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    cmd_aliases => 'S',
    default => 'Simple',
    documentation => "The Catmandu::Store class to use. Defaults to Simple.",
);

has store_arg => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    cmd_aliases => 's',
    default => sub { +{} },
    documentation => "Pass params to the store constructor.",
);

has index => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    cmd_aliases => 'I',
    default => 'Simple',
    documentation => "The Catmandu::Index class to use. Defaults to Simple.",
);

has index_arg => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    cmd_aliases => 'i',
    default => sub { +{} },
    documentation => "Pass params to the index constructor.",
);

has map => (
    traits => ['Getopt'],
    is => 'rw',
    isa => IO_All,
    coerce => 1,
);

sub _usage_format {
    "usage: %c %o conf_file"
}

sub BUILD {
    my $self = shift;

    $self->store =~ /::/ or $self->store("Catmandu::Store::" . $self->store);
    $self->index =~ /::/ or $self->index("Catmandu::Index::" . $self->index);

    if (my $file = shift @{$self->extra_argv}) {
        $self->map($file);
    }
} 

sub run {
    my $self = shift;

    Plack::Util::load_class($self->index);
    Plack::Util::load_class($self->store);

    my $index = $self->index->new($self->index_arg);
    my $store = $self->store->new($self->store_arg);
   
    my %map = $self->parse_map;


    print "Indexing: ";

    my $count = 0;
    $store->each(sub {
        my $obj = shift;  
    
        my %idx_obj = ();

        foreach my $key (keys %map) {
            foreach my $path (@{$map{$key}}) {
                my $jpath  = JSON::Path->new($path);
                my @values = $jpath->values($obj);

                push(@{$idx_obj{$key}}, @values);
            }
        }

        print ".";
        $index->save($obj);

        $count++;
    });

    print "\n";

    print "Indexed: $count objects\n";
}

sub parse_map {
    my $self = shift;

    my %map = ();

    foreach my $line (split(/\n/,$self->map->slurp)) {
        $line =~ s/^\s*(.*)\s*$/$1/;
        my ($path, $index) = split(/\s+/,$line);
        push(@{$map{$index}}, $path);
    }

    return %map;
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;
