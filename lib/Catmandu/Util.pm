package Catmandu::Util;
use Catmandu::Sane;
use Exporter qw(import);
use Plack::Util;
use IO::Handle;
use IO::String;
use IO::File;

our @EXPORT_OK = qw(
    load_package
    create_package
    add_parent
    get_subroutine_info
    get_subroutine
    add_subroutine
    io
    is_instance
    is_able
    is_value
    is_quoted
    unquote
    trim
);

*load_package = \&Plack::Util::load_class;

sub create_package {
    my ($pkg) = @_;
    state $prefix = 'Catmandu::__SERIAL_PACKAGES__::';
    state $serial = 0;
    $pkg ||= $prefix . ++$serial;
    eval "package $pkg;'$pkg'" or confess $@;
}

sub add_parent {
    my ($pkg, @isa) = @_;
    no strict 'refs';
    push @{"${pkg}::ISA"}, @isa;
    @isa;
}

sub get_subroutine_info {
    my ($pkg, $sub, %opts) = @_;
    my $isa = $opts{parents} ? mro::get_linear_isa($pkg) : [$pkg];

    for $pkg (@$isa) {
        no strict 'refs';
        my @syms = values %{"${pkg}::"};
        use strict;
        for my $sym (@syms) {
            next unless ref \$sym eq 'GLOB';

            if (*{$sym}{CODE} && *{$sym}{CODE} == $sub) {
                return wantarray ? ($pkg, *{$sym}{NAME}) : join('::', $pkg, *{$sym}{NAME});
            }
        }
    }

    return;
}

sub get_subroutine {
    my ($pkg, $sym, %opts) = @_;
    my $isa = $opts{parents} ? mro::get_linear_isa($pkg) : [$pkg];

    for $pkg (@$isa) {
        no strict 'refs';
        if (defined &{"${pkg}::$sym"}) {
            return \&{"${pkg}::$sym"};
        }
    }

    return;
}

sub add_subroutine {
    my ($pkg, %pairs) = @_;

    my @syms = keys %pairs;

    for my $sym (@syms) {
        my $sub = $pairs{$sym};
        unless (ref $sub) {
            $sub = eval "package $pkg; $sub" or confess $@;
        }
        no strict 'refs';
        *{"${pkg}::$sym"} = $sub;
    }

    @syms;
}

sub io {
    my ($io, @args) = @_;

    my $io_obj;

    if (ref($io) eq 'SCALAR') {
        $io_obj = IO::String->new($$io);
    }
    elsif (ref(\$io) eq 'GLOB' || ref($io)) {
        $io_obj = IO::Handle->new_from_fd($io, @args);
    }
    else {
        $io_obj = IO::File->new;
        $io_obj->open($io, @args);
    }

    binmode $io_obj, ':utf8';

    $io_obj;
}

sub is_instance {
    my $obj = shift;
    return 0 unless blessed($obj);
    $obj->isa($_) || return 0 foreach @_;
    return 1;
}

sub is_able {
    my $obj = shift;
    return 0 unless blessed($obj);
    $obj->can($_) || return 0 foreach @_;
    return 1;
}

sub is_value {
    my $val = $_[0]; defined($val) && !ref($val) && ref(\$val) ne 'GLOB';
}

sub is_quoted {
    my $str = $_[0];

    $str and $str =~ /^\"(.*)\"$/ or
             $str =~ /^\'(.*)\'$/;
}

sub unquote {
    my $str = $_[0];

    if ($str) {
        $str =~ s/^\"(.*)\"$/$1/s or
        $str =~ s/^\'(.*)\'$/$1/s;
    }

    $str;
}

sub trim {
    my $str = $_[0];

    if ($str) {
        $str =~ s/^\s+//s;
        $str =~ s/\s+$//s;
    }

    $str;
}

1;
