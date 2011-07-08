package Catmandu::Util;
use Catmandu::Sane;
use Exporter qw(import);
use List::Util;
use Data::UUID;
use IO::File;
use IO::String;

our @EXPORT_OK = qw(
    load_package
    add_parent
    add_sub

    quack
    value

    new_id
    get_id
    ensure_id
    assert_id
    ensure_collection
    assert_collection

    opts

    group_by
    pluck

    trim

    io
);

sub load_package { # stolen from Plack::Util
    my ($pkg, $prefix) = @_;

    if ($prefix) {
        unless ($pkg =~ s/^\+// || $pkg =~ /^$prefix/) {
            $pkg = "${prefix}::$pkg";
        }
    }

    my $file = "$pkg.pm";
    $file =~ s!::!/!g;

    require $file;

    $pkg;
}

sub add_parent {
    my ($pkg, @isa) = @_;

    no strict 'refs';
    push @{"${pkg}::ISA"}, @isa;
    @isa
}

sub add_sub {
    my ($pkg, %args) = @_;

    my @syms = keys %args;

    for my $sym (@syms) {
        my $sub = $args{$sym};
        unless (ref $sub) {
            $sub = eval "package $pkg; $sub" or confess $@;
        }
        no strict 'refs';
        *{"${pkg}::$sym"} = $sub;
    }

    @syms;
}

sub quack {
    my $obj = shift;
    blessed($obj) || return 0;
    $obj->can($_) || return 0 foreach @_;
    1;
}

sub value {
    my $val = $_[0]; defined($val) && !ref($val) && ref(\$val) ne 'GLOB';
}

sub new_id {
    Data::UUID->new->create_str;
}

sub get_id {
    ref $_[0] ? $_[0]->{_id} : $_[0];
}

sub ensure_id {
    $_[0]->{_id} ||= new_id;
}

sub assert_id {
    get_id(@_) || confess("missing _id");
}

sub ensure_collection {
    $_[0]->{_collection} = $_[1] || confess("missing _collection");
}

sub assert_collection {
    $_[0]->{_collection} || confess("missing _collection");
}

sub opts {
    ref $_[0] ? $_[0] : {@_};
}

sub group_by {
    my ($key, $list) = @_;
    List::Util::reduce { my $k = $b->{$key}; push @{$a->{$k} ||= []}, $b if defined $k; $a } {}, @$list;
}

sub pluck {
    my ($key, $list) = @_;
    my @vals = map { $_->{$key} } @$list;
    \@vals;
}

sub trim {
    my $str = $_[0];

    if ($str) {
        $str =~ s/^\s+//s;
        $str =~ s/\s+$//s;
    }

    $str;
}

sub io {
    my ($io, @args) = @_;

    my $io_obj;

    if (ref($io) eq 'SCALAR') {
        $io_obj = IO::String->new($$io);
    } elsif (ref(\$io) eq 'GLOB' || ref($io)) {
        $io_obj = IO::Handle->new_from_fd($io, @args);
    } else {
        $io_obj = IO::File->new;
        $io_obj->open($io, @args);
    }

    binmode $io_obj, ':utf8';

    $io_obj;
}

1;
