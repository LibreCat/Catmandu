package Catmandu::Util;

use Catmandu::Sane;
use Exporter qw(import);
use Sub::Quote ();
use Data::Util;
use List::Util;
use Data::Compare ();
use IO::File;
use IO::String;
use YAML::Any ();
use JSON ();

our %EXPORT_TAGS = (
    misc    => [qw(require_package use_lib)],
    io      => [qw(io read_file read_yaml read_json)],
    data    => [qw(parse_data_path get_data set_data delete_data data_at)],
    array   => [qw(array_exists array_group_by array_pluck array_to_sentence
        array_sum array_includes array_any array_rest array_uniq)],
    string  => [qw(as_utf8 trim capitalize)],
    is      => [qw(is_same is_different)],
    check   => [qw(check_same check_different)],
);

our @EXPORT_OK = map { @$_ } values %EXPORT_TAGS;

$EXPORT_TAGS{all} = \@EXPORT_OK;

sub use_lib {
    my (@dirs) = @_;

    use lib;
    lib->import(@dirs);
    confess $@ if $@;

    1;
}

sub require_package {
    my ($pkg, $ns) = @_;

    if ($ns) {
        unless ($pkg =~ s/^\+// || $pkg =~ /^$ns/) {
            $pkg = "${ns}::$pkg";
        }
    }

    eval "require $pkg";
    confess $@ if $@;

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

sub read_file {
    local $/;
    open(my $fh, check_string($_[0])) or confess "can't read file '$_[0]'";
    my $str = <$fh>;
    close($fh);
    $str;
}

sub read_yaml {
    YAML::Any::LoadFile($_[0]);
}

sub read_json {
    JSON::decode_json(read_file($_[0]));
}

sub parse_data_path {
    my ($path) = @_;
    check_string($path);
    $path = [ split /[\/\.]/, $path ];
    my $key = pop @$path;
    return $path, $key;
}

sub get_data {
    my ($data, $key) = @_;
    if (is_array_ref($data)) {
        given ($key) {
            when ('$first') { return unless @$data; $key = 0 }
            when ('$last')  { return unless @$data; $key = @$data - 1 }
            when ('*')      { return @$data }
        }
        if (array_exists($data, $key)) {
            return $data->[$key];
        }
        return;
    }
    if (is_hash_ref($data) && exists $data->{$key}) {
        return $data->{$key};
    }
    return;
}

sub set_data {
    my ($data, $key, @vals) = @_;
    if (is_array_ref($data)) {
        given ($key) {
            when ('$first')   { return unless @$data; $key = 0 }
            when ('$last')    { return unless @$data; $key = @$data - 1 }
            when ('$prepend') { unshift @$data, $vals[0]; return $vals[0] }
            when ('$append')  { push    @$data, $vals[0]; return $vals[0] }
            when ('*')        { return splice @$data, 0, @$data, @vals }
        }
        return $data->[$key] = $vals[0] if is_natural($key);
        return;
    }
    if (is_hash_ref($data)) {
        return $data->{$key} = $vals[0];
    }
    return;
}

sub delete_data {
    my ($data, $key) = @_;
    if (is_array_ref($data)) {
        given ($key) {
            when ('$first') { return unless @$data; $key = 0 }
            when ('$last')  { return unless @$data; $key = @$data - 1 }
            when ('*')      { return splice @$data, 0, @$data }
        }
        if (array_exists($data, $key)) {
            return splice @$data, $key, 1;
        }
        return;
    }
    if (is_hash_ref($data) && exists $data->{$key}) {
        return delete $data->{$key};
    }

    return;
}

sub data_at {
    my ($path, $data, %opts) = @_;
    $path = [@$path];
    my $create = $opts{create};
    my $_key = $opts{_key} // $opts{key};
    if (defined $opts{key} && $create && @$path) {
        push @$path, $_key;
    }
    my $key;
    while (defined(my $key = shift @$path)) {
        ref $data || return;
        if (is_array_ref($data)) {
            if ($key eq '*') {
                return map { data_at($path, $_, create => $create, _key => $_key) } @$data;
            } else {
                given ($key) {
                    when ('$first')   { $key = 0 }
                    when ('$last')    { $key = -1 }
                    when ('$prepend') { unshift @$data, undef; $key = 0 }
                    when ('$append')  { $key = @$data }
                }
                is_integer($key) || return;
                if ($create && @$path) {
                    $data = $data->[$key] ||= is_integer($path->[0]) || ord($path->[0]) == ord('$') ? [] : {};
                } else {
                    $data = $data->[$key];
                }
            }
        } elsif ($create && @$path) {
            $data = $data->{$key} ||= is_integer($path->[0]) || ord($path->[0]) == ord('$') ? [] : {};
        } else {
            $data = $data->{$key};
        }
        if ($create && @$path == 1) {
            last;
        }
    }
    $data;
}

sub array_exists {
    my ($arr, $i) = @_;
    is_natural($i) && $i < @$arr;
}

sub array_group_by {
    my ($arr, $key) = @_;
    List::Util::reduce { my $k = $b->{$key}; push @{$a->{$k} ||= []}, $b if defined $k; $a } {}, @$arr;
}

sub array_pluck {
    my ($arr, $key) = @_;
    my @vals = map { $_->{$key} } @$arr;
    \@vals;
}

sub array_to_sentence {
    my ($arr, $join_char, $join_last_char) = @_;
    $join_char //= ', ';
    $join_last_char //= ' and ';
    my $size = scalar @$arr;
    $size > 2
        ? join($join_last_char, join($join_char, @$arr[0..$size-1]), $arr->[-1])
        : join($join_last_char, @$arr);
}

sub array_sum {
    List::Util::sum(0, @{$_[0]});
}

sub array_includes {
    my ($arr, $val) = @_;
    is_same($val, $_) && return 1 for @$arr;
    0;
}

sub array_any {
    my ($arr, $sub) = @_;
    $sub->($_) && return 1 for @$arr;
    0;
}

sub array_rest {
    my ($arr) = @_;
    @$arr < 2 ? [] : [@$arr[1..(@$arr-1)]];
}

sub array_uniq {
    my ($arr) = @_;
    my %seen = ();
    [grep { not $seen{$_}++ } @$arr];
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

sub is_same { goto &Data::Compare::Compare }

sub is_different {
    !is_same(@_);
}

sub check_same {
    is_same(@_) || confess('error: should be same');
}

sub check_different {
    !is_same(@_) || confess('error: should be different');
}

sub is_invocant { goto &Data::Util::is_invocant }
sub is_scalar_ref { goto &Data::Util::is_scalar_ref }
sub is_array_ref { goto &Data::Util::is_array_ref }
sub is_hash_ref { goto &Data::Util::is_hash_ref }
sub is_code_ref { goto &Data::Util::is_code_ref }
sub is_regex_ref { goto &Data::Util::is_rx }
sub is_glob_ref { goto &Data::Util::is_glob_ref }
sub is_value { goto &Data::Util::is_value }
sub is_string { goto &Data::Util::is_string }
sub is_number { goto &Data::Util::is_number }
sub is_integer { goto &Data::Util::is_integer }

sub is_natural {
    is_integer($_[0]) && $_[0] >= 0;
}

sub is_positive {
    is_integer($_[0]) && $_[0] >= 1;
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
    confess('type error: should be able to '.array_to_sentence(\@_));
}

sub check_maybe_able {
    my $obj = shift;
    return $obj if is_maybe_able($obj, @_);
    confess('type error: should be undef or able to '.array_to_sentence(\@_));
}

for my $sym (qw(able invocant ref
        scalar_ref array_ref hash_ref code_ref regex_ref glob_ref
        value string number integer natural positive)) {
    my $pkg = __PACKAGE__;
    my $err_name = $sym;
    $err_name =~ s/_/ /;
    push @EXPORT_OK, "is_$sym", "is_maybe_$sym", "check_$sym", "check_maybe_$sym";
    push @{$EXPORT_TAGS{is}}, "is_$sym", "is_maybe_$sym";
    push @{$EXPORT_TAGS{check}}, "check_$sym", "check_maybe_$sym";
    Sub::Quote::quote_sub("${pkg}::is_maybe_$sym",
        "!defined(\$_[0]) || ${pkg}::is_$sym(\@_)")
            unless Data::Util::get_code_ref($pkg, "is_maybe_$sym");
    Sub::Quote::quote_sub("${pkg}::check_$sym",
        "${pkg}::is_$sym(\@_) || ${pkg}::confess('type error: should be $err_name'); \$_[0]")
            unless Data::Util::get_code_ref($pkg, "check_$sym");
    Sub::Quote::quote_sub("${pkg}::check_maybe_$sym",
        "${pkg}::is_maybe_$sym(\@_) || ${pkg}::confess('type error: should be undef or $err_name'); \$_[0]")
            unless Data::Util::get_code_ref($pkg, "check_maybe_$sym");
}

1;
