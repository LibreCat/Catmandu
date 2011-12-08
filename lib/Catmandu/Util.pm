package Catmandu::Util;

use Catmandu::Sane;
use Exporter qw(import);
use Sub::Quote ();
use Data::Util;
use List::Util;
use Data::Compare ();
use IO::File;
use IO::String;

our @EXPORT_OK = qw(
    load_package io
    get_data_at
    group_by pluck to_sentence
    as_utf8 trim capitalize
    is_same check_same
);

our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    array  => [qw(group_by pluck to_sentence)],
    string => [qw(as_utf8 trim capitalize)],
    is     => [qw(is_same)],
    check  => [qw(check_same)],
);

sub load_package {
    my ($pkg, $prefix) = @_;

    if ($prefix) {
        unless ($pkg =~ s/^\+// || $pkg =~ /^$prefix/) {
            $pkg = "${prefix}::${pkg}";
        }
    }

    eval "require $pkg" or confess $@;

    $pkg;
}

sub io {
    my ($io, %opts) = @_;
    $opts{encoding} ||= ':utf8';
    $opts{mode} ||= 'r';

    my $io_obj;

    if (is_scalar_ref($io)) {
        $io_obj = IO::String->new($$io);
    } elsif (is_glob_ref(\$io) || ref $io) {
        $io_obj = IO::Handle->new_from_fd($io, $opts{mode});
    } else {
        $io_obj = IO::File->new;
        $io_obj->open($io, $opts{mode});
    }

    binmode $io_obj, $opts{encoding};

    $io_obj;
}

sub get_data_at {
    my ($path, $data) = @_;
    if (ref $path) {
        $path = [@$path];
    } else {
        $path = [split /\./, $path];
    }
    while (my $key = shift @$path) {
        ref $data || return;
        if (is_array_ref($data)) {
            if ($key eq '*') {
                return map { get_data_at($path, $_) } @$data;
            } else {
                is_natural($key) || return;
                $data = $data->[$key];
            }
        } else {
            $data = $data->{$key};
        }
    }
    $data;
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

sub to_sentence {
    my ($join_char, $join_last_char, $list) = @_;
    my $size = scalar @$list;
    $size > 2
        ? join($join_last_char, join($join_char, @$list[0..$size-1]), $list->[-1])
        : join($join_last_char, @$list);
}

sub as_utf8 {
    my $str = $_[0];
    utf8::upgrade($str);
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

sub capitalize {
    ucfirst lc as_utf8 $_[0];
}

sub is_same {
    Data::Compare::Compare($_[0], $_[1]);
}

sub check_same {
    is_same(@_) || confess('error: should be the same');
}

*is_invocant = \&Data::Util::is_invocant;
*is_scalar_ref = \&Data::Util::is_scalar_ref;
*is_array_ref = \&Data::Util::is_array_ref;
*is_hash_ref = \&Data::Util::is_hash_ref;
*is_code_ref = \&Data::Util::is_code_ref;
*is_regex_ref = \&Data::Util::is_rx;
*is_glob_ref = \&Data::Util::is_glob_ref;
*is_value = \&Data::Util::is_value;
*is_string = \&Data::Util::is_string;
*is_number = \&Data::Util::is_number;
*is_integer = \&Data::Util::is_integer;

sub is_natural {
    is_integer($_[0]) && $_[0] >= 0;
}

sub is_ref {
    ref $_[0] ? 1 : 0;
}

sub is_able {
    my $obj = shift;
    is_invocant($obj) || return 0;
    $obj->can($_)     || return 0 for @_;
    1;
}

sub check_able {
    my $obj = shift;
    return $obj if is_able($obj, @_);
    confess('type error: should be able to '.to_sentence(', ', ' and ', \@_));
}

sub check_maybe_able {
    my $obj = shift;
    return $obj if is_maybe_able($obj, @_);
    confess('type error: should be undef or able to '.to_sentence(', ', ' and ', \@_));
}

for my $sym (qw(able invocant ref
        scalar_ref array_ref hash_ref code_ref regex_ref glob_ref
        value string number integer natural)) {
    my $pkg = __PACKAGE__;
    push @EXPORT_OK, "is_$sym", "is_maybe_$sym", "check_$sym", "check_maybe_$sym";
    push @{$EXPORT_TAGS{is}}, "is_$sym", "is_maybe_$sym";
    push @{$EXPORT_TAGS{check}}, "check_$sym", "check_maybe_$sym";
    Sub::Quote::quote_sub("${pkg}::is_maybe_$sym",
        "!defined(\$_[0]) || ${pkg}::is_$sym(\@_)")
            unless Data::Util::get_code_ref($pkg, "is_maybe_$sym");
    Sub::Quote::quote_sub("${pkg}::check_$sym",
        "${pkg}::is_$sym(\@_) || ${pkg}::confess('type error: should be $sym'); \$_[0]")
            unless Data::Util::get_code_ref($pkg, "check_$sym");
    Sub::Quote::quote_sub("${pkg}::check_maybe_$sym",
        "${pkg}::is_maybe_$sym(\@_) || ${pkg}::confess('type error: should be undef or $sym'); \$_[0]")
            unless Data::Util::get_code_ref($pkg, "check_maybe_$sym");
}

1;
