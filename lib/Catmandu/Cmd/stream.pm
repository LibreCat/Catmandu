package Catmandu::Cmd::stream;

use Catmandu::Sane;

our $VERSION = '1.0505';

use parent 'Catmandu::Cmd';
use Catmandu;
use Catmandu::Util;
use Carp;
use IO::Handle;
use IO::File;
use namespace::clean;

sub command_opt_spec {
    (["verbose|v", ""], ["delete", "delete existing objects first"],);
}

sub command {
    my ($self, $opts, $args) = @_;

    my ($from_args, $from_opts, $into_args, $into_opts)
        = $self->_parse_options($args);

    my $id_name;
    my $bag_name;
    my $store_name;
    my $store_opts;
    my $filename;
    my $upload;

    if ($bag_name = $from_opts->{bag}) {
        delete $from_opts->{bag};
        $id_name = $from_opts->{id} // $self->usage_error("need a --id");
        delete $from_opts->{id};
        $store_name = $from_args->[0];
        $store_opts = $from_opts;
        $filename   = $into_args->[0];
        $upload     = 0;
    }
    elsif ($bag_name = $into_opts->{bag}) {
        delete $into_opts->{bag};
        $id_name = $into_opts->{id} // $self->usage_error("need a --id");
        delete $into_opts->{id};
        $store_name = $into_args->[0];
        $store_opts = $into_opts;
        $filename   = $from_args->[0];
        $upload     = 1;
    }
    else {
        $self->usage_error("need a --bag");
    }

    my $store = Catmandu->store($store_name, $store_opts);

    return $upload
        ? $self->upload_file($store, $bag_name, $id_name, $filename)
        : $self->download_file($store, $bag_name, $id_name, $filename);
}

sub upload_file {
    my ($self, $store, $bag_name, $id_name, $filename) = @_;

    unless ($store->bag->exists($bag_name)) {
        $store->bag->add({_id => $bag_name});
    }

    my $bag = $store->bag->files($bag_name);

    my $io;

    if (!defined($filename) || $filename eq '-') {
        $io = IO::Handle->new();
        $io->fdopen(fileno(STDIN), "r");
    }
    else {
        $io = IO::File->new("<$filename");
    }

    croak "can't open $filename for reading" unless defined($io);

    $bag->upload($io, $id_name);
}

sub download_file {
    my ($self, $store, $bag_name, $id_name, $filename) = @_;

    unless ($store->bag->exists($bag_name)) {
        carp "No such bag `$bag_name`";
    }

    my $bag = $store->bag->files($bag_name);

    my $file = $bag->get($id_name);

    unless ($file) {
        carp "No such file `$id_name` in `$bag_name`";
    }

    my $io;

    if (!defined($filename) || $filename eq '-') {
        $io = bless(\*STDOUT => 'IO::File');
    }
    else {
        $io = IO::File->new(">$filename");
    }

    $io->binmode(':encoding(UTF-8)');

    croak "can't open $filename for writing" unless defined($io);

    $bag->stream($io, $file);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::stream - import and export streams into a Catmandu::FileStore

=head1 EXAMPLES

  catmandu stream /tmp/data.txt to File::Simple --root t/data --bag 1234

  catmandu stream File::Simple --root t/data --bag 1234 to /tmp/data

  catmandu help stream

=cut
