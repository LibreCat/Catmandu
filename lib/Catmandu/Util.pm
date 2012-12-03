package Catmandu::Util;

use Catmandu::Sane;
use Exporter qw(import);
use Sub::Quote ();
use Data::Util;
use List::Util;
use Data::Compare ();
use IO::File;
use IO::String;
use File::Spec;
use YAML::Any ();
use JSON ();

our %EXPORT_TAGS = (
    io     => [qw(io read_file write_file read_yaml read_json join_path
        normalize_path segmented_path)],
    data   => [qw(parse_data_path get_data set_data delete_data data_at)],
    array  => [qw(array_exists array_group_by array_pluck array_to_sentence
        array_sum array_includes array_any array_rest array_uniq)],
    string => [qw(as_utf8 trim capitalize)],
    is     => [qw(is_same is_different)],
    check  => [qw(check_same check_different)],
    human  => [qw(human_number human_content_type human_byte_size)],
    xml    => [qw(xml_declaration xml_escape)],
    misc   => [qw(require_package use_lib)],
);

our @EXPORT_OK = map { @$_ } values %EXPORT_TAGS;

$EXPORT_TAGS{all} = \@EXPORT_OK;

my $HUMAN_CONTENT_TYPES = {
    # txt
    'text/plain' => 'Text',
    'application/txt' => 'Text',
    # pdf
    'application/pdf' => 'PDF',
    'application/x-pdf' => 'PDF',
    'application/acrobat' => 'PDF',
    'applications/vnd.pdf' => 'PDF',
    'text/pdf' => 'PDF',
    'text/x-pdf' => 'PDF',
    # doc
    'application/doc' => 'Word',
    'application/vnd.msword' => 'Word',
    'application/vnd.ms-word' => 'Word',
    'application/winword' => 'Word',
    'application/word' => 'Word',
    'application/x-msw6' => 'Word',
    'application/x-msword' => 'Word',
    # docx
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'Word',
    # xls
    'application/vnd.ms-excel' => 'Excel',
    'application/msexcel' => 'Excel',
    'application/x-msexcel' => 'Excel',
    'application/x-ms-excel' => 'Excel',
    'application/vnd.ms-excel' => 'Excel',
    'application/x-excel' => 'Excel',
    'application/x-dos_ms_excel' => 'Excel',
    'application/xls' => 'Excel',
    # xlsx
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => 'Excel',
    # ppt
    'application/vnd.ms-powerpoint' => 'PowerPoint',
    'application/mspowerpoint' => 'PowerPoint',
    'application/ms-powerpoint' => 'PowerPoint',
    'application/mspowerpnt' => 'PowerPoint',
    'application/vnd-mspowerpoint' => 'PowerPoint',
    'application/powerpoint' => 'PowerPoint',
    'application/x-powerpoint' => 'PowerPoint',
    # pptx
    'application/vnd.openxmlformats-officedocument.presentationml.presentation' => 'PowerPoint',
    # csv
    'text/comma-separated-values' => 'CSV',
    'text/csv' => 'CSV',
    'application/csv' => 'CSV',
    # zip
    'application/zip' => 'ZIP archive',
};

my $XML_DECLARATION = qq(<?xml version="1.0" encoding="UTF-8"?>\n);

sub io {
    my ($io, %opts) = @_;
    my $binmode = $opts{binmode} || $opts{encoding} || ':utf8';
    my $mode = $opts{mode} || 'r';
    my $fh;

    if (is_scalar_ref($io)) {
        $fh = IO::String->new($$io);
    } elsif (is_glob_ref(\$io) || ref $io) {
        $fh = IO::Handle->new_from_fd($io, $mode);
    } else {
        $fh = IO::File->new;
        $fh->open($io, $mode);
    }

    binmode $fh, $binmode;

    $fh;
}

sub read_file {
    my ($path) = @_;
    local $/;
    open my $fh, "<", $path or confess qq(can't open "$path" for reading);
    my $str = <$fh>;
    close $fh;
    $str;
}

sub write_file {
    my ($path, $str) = @_;
    open my $fh, ">", $path or confess qq(can't open "$path" for writing);
    print $fh $str;
    close $fh;
    $path;
}

sub read_yaml {
    YAML::Any::LoadFile($_[0]);
}

sub read_json {
    JSON::decode_json(read_file($_[0]));
}

sub join_path {
    my $path = File::Spec->catfile(@_);
    normalize_path($path);
}

sub normalize_path { # taken from Dancer::FileUtils
    my ($path) = @_;
    $path =~ s!/\./!/!g;
    while ($path =~ s![^/]*/\.\./!!) {}
    $path;
}

sub segmented_path {
    my ($id, %opts) = @_;
    my $segment_size = $opts{segment_size} || 3;
    my $base_path = $opts{base_path};
    $id =~ s/[^0-9a-zA-Z]+//g;
    my @path = unpack "(A$segment_size)*", $id;
    defined $base_path
        ? File::Spec->catdir($base_path, @path)
        : File::Spec->catdir(@path);
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
    return unless @vals;
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
    my ($arr, $join, $join_last) = @_;
    $join //= ', ';
    $join_last //= ' and ';
    my $size = scalar @$arr;
    $size > 2
        ? join($join_last, join($join, @$arr[0..$size-1]), $arr->[-1])
        : join($join_last, @$arr);
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
    my @vals = grep { not $seen{$_}++ } @$arr;
    \@vals;
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
    my $str = $_[0];
    utf8::upgrade($str);
    ucfirst lc $str;
}

*is_same = \&Data::Compare::Compare;

sub is_different {
    !is_same(@_);
}

sub check_same {
    is_same(@_) || confess('error: should be same');
}

sub check_different {
    !is_same(@_) || confess('error: should be different');
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

sub human_number { # taken from Number::Format
    my $num = $_[0];
    # add leading 0's so length($num) is divisible by 3
    $num = '0'x(3 - (length($num) % 3)).$num;
    # split $num into groups of 3 characters and insert commas
    $num = join ',', grep { $_ ne '' } split /(...)/, $num;
    # strip off leading zeroes and/or comma
    $num =~ s/^0+,?//;
    length $num ? $num : '0';
}

sub human_byte_size {
    my ($size) = @_;
    if ($size > 1000000000) {
        return sprintf("%.2f GB", $size / 1000000000);
    } elsif ($size > 1000000) {
        return sprintf("%.2f MB", $size / 1000000);
    } elsif ($size > 1000) {
        return sprintf("%.2f KB", $size / 1000);
    }
    "$size bytes";
}

sub human_content_type {
    my ($content_type, $default) = @_;
    my ($key) = $content_type =~ /^([^;]+)/;
    $HUMAN_CONTENT_TYPES->{$key} // $default // $content_type;
}

sub xml_declaration {
    $XML_DECLARATION;
}

sub xml_escape {
    my ($str) = @_;
    utf8::upgrade($str);

    $str =~ s/&/&amp;/go;
    $str =~ s/</&lt;/go;
    $str =~ s/>/&gt;/go;
    $str =~ s/"/&quot;/go;
    $str =~ s/'/&apos;/go;
    # remove control chars
    $str =~ s/[^\x09\x0A\x0D\x20-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]//go;

    $str;
}

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

    return $pkg if is_invocant($pkg);

    eval "require $pkg;1;" or do {
        my $err = $@;
        confess $err;
    };

    $pkg;
}

1;

__END__

=head1 NAME

Catmandu::Util - A collection of utility functions

=head1 SYNOPSIS

    use Catmandu::Util qw(:string);

    $str = trim($str);

=head1 FUNCTIONS

=head2 IO functions

    use Catmandu::Util qw(:io);

=over 4

=item io($io, %opts)

Takes a file path, glob, glob reference, scalar reference or L<IO::Handle>
object and returns an opened L<IO::Handle> object.

    my $fh = io '/path/to/file';

    my $fh = io *STDIN;

    my $fh = io \*STDOUT, mode => 'w', binmode => ':crlf';

    my $scalar = "";
    my $fh = io \$scalar, mode => 'w';
    $fh->print("some text");

Options are:

=over 12

=item mode

Default is C<"r">.

=item binmode

Default is C<":utf8">.

=item encoding

Alias for C<binmode>.

=back

=item read_file($path);

Reads the file at C<$path> into a string.

    my $str = read_file('/path/to/file.txt');

=item write_file($path, $str);

Writes the string C<$str> to a file at C<$path>.

    write_file('/path/to/file.txt', "contents");

=item read_yaml($path);

    my $cfg = read_yaml('config.yaml');

=item read_json($path);

    my $cfg = read_json('config.json');

=item join_path(@path);

    join_path('/path/..', './to', 'file.txt');
    # => "/to/file.txt"

=item normalize_path($path);

    normalize_path('/path/../to/./file.txt');
    # => "/to/file.txt"

=item segmented_path($path);

    my $id = "FB41144C-F0ED-11E1-A9DE-61C894A0A6B4";
    segmented_path($id, segment_size => 4);
    # => "FB41/144C/F0ED/11E1/A9DE/61C8/94A0/A6B4"
    segmented_path($id, segment_size => 2, base_path => "/files");
    # => "/files/FB/41/14/4C/F0/ED/11/E1/A9/DE/61/C8/94/A0/A6/B4"

=back

=head2 Array functions

    use Catmandu::Util qw(:array);

A collection of functions that operate on array references.

=over 4

=item array_exists($array, $index)

Returns C<1> if C<$index> is in the bounds of C<$array>

    array_exists(["a", "b"], 2);
    # => 0
    array_exists(["a", "b"], 1);
    # => 1

=item array_group_by($array, $key)

    my $list = [{color => 'black', id => 1},
                {color => 'white', id => 2},
                {id => 3},
                {color => 'black', id => 4}];
    array_group_by($list, 'color');
    # => {black => [{color => 'black', id => 1}, {color => 'black', id => 4}],
    #     white => [{color => 'white', id => 2}]}

=item array_pluck($array, $key)

    my $list = [{id => 1}, {}, {id => 3}];
    array_pluck($list, 'id');
    # => [1, undef, 3]

=item array_to_sentence($array)

=item array_to_sentence($array, $join)

=item array_to_sentence($array, $join, $join_last)

    array_to_sentence([1,2,3]);
    # => "1, 2 and 3"
    array_to_sentence([1,2,3], ",");
    # => "1,2 and 3"
    array_to_sentence([1,2,3], ",", " & ");
    # => "1,2 & 3"

=item array_sum($array)

    array_sum([1,2,3]);
    # => 6

=item array_includes($array, $val)

Returns 1 if C<$array> includes a value that is deeply equal to C<$val>, 0
otherwise. Comparison is done with C<is_same()>.

    array_includes([{color => 'black'}], {color => 'white'});
    # => 0
    array_includes([{color => 'black'}], {color => 'black'});
    # => 1

=item array_any($array, \&sub)

    array_any(["green", "blue"], sub { my $color = $_[0]; $color eq "blue" });
    # => 1

=item array_rest($array)

Returns a copy of C<$array> without the head.

    array_rest([1,2,3,4]);
    # => [2,3,4]
    array_rest([1]);
    # => []

=item array_uniq($array)

Returns a copy of C<$array> with all duplicates removed. Comparison is done
with C<is_same()>.

=back

=head2 String functions

    use Catmandu::Util qw(:string);

=over 4

=item as_utf8($str)

Returns a copy of C<$str> flagged as UTF-8.

=item trim($str)

Returns a copy of C<$str> with leading and trailing whitespace removed.

=item capitalize($str)

Equivalent to C<< ucfirst lc as_utf8 $str >>.

=back

=head2 Is functions

    use Catmandu::Util qw(:is);

    is_number(42) ? "it's numeric" : "it's not numeric";

    is_maybe_hash_ref({});
    # => 1
    is_maybe_hash_ref(undef);
    # => 1
    is_maybe_hash_ref([]);
    # => 0

A collection of predicate functions that test the type or value of argument
C<$val>.  Each function (except C<is_same()> and C<is_different>) also has a
I<maybe> variant that also tests true if C<$val> is undefined.
Returns C<1> or C<0>.

=over 4

=item is_invocant($val)

=item is_maybe_invocant($val)

Tests if C<$val> is callable (is an existing package or blessed object).

=item is_able($val, @method_names)

=item is_maybe_able($val, @method_names)

Tests if C<$val> is callable and has all methods in C<@method_names>.

=item is_ref($val)

=item is_maybe_ref($val)

Tests if C<$val> is a reference. Equivalent to C<< ref $val ? 1 : 0 >>.

=item is_scalar_ref($val)

=item is_maybe_scalar_ref($val)

Tests if C<$val> is a scalar reference.

=item is_array_ref($val)

=item is_maybe_array_ref($val)

Tests if C<$val> is an array reference.

=item is_hash_ref($val)

=item is_maybe_hash_ref($val)

Tests if C<$val> is a hash reference.

=item is_code_ref($val)

=item is_maybe_code_ref($val)

Tests if C<$val> is a subroutine reference.

=item is_regex_ref($val)

=item is_maybe_regex_ref($val)

Tests if C<$val> is a regular expression reference generated by the C<qr//>
operator.

=item is_glob_ref($val)

=item is_maybe_glob_ref($val)

Tests if C<$val> is a glob reference.

=item is_value($val)

=item is_maybe_value($val)

Tests if C<$val> is a real value (defined, not a reference and not a
glob.

=item is_string($val)

=item is_maybe_string($val)

Tests if C<$val> is a non-empty string.
Equivalent to C<< is_value($val) && length($val) > 0 >>.

=item is_number($val)

=item is_maybe_number($val)

Tests if C<$val> is a number.

=item is_integer($val)

=item is_maybe_integer($val)

Tests if C<$val> is an integer.

=item is_natural($val)

=item is_maybe_natural($val)

Tests if C<$val> is a non-negative integer.
Equivalent to C<< is_integer($val) && $val >= 0 >>.

=item is_positive($val)

=item is_maybe_positive($val)

Tests if C<$val> is a positive integer.
Equivalent to C<< is_integer($val) && $val >= 1 >>.

=item is_same($val, $other_val)

Tests if C<$val> is deeply equal to C<$other_val>.

=item is_different($val, $other_val)

The opposite of C<is_same()>.

=back

=head2 Check functions

    use Catmandu::Util qw(:check);

    check_hash_ref({color => 'red'});
    # => {color => 'red'}
    check_hash_ref([]);
    # dies

A group of assert functions similar to the C<:is> group, but instead of
returning true or false they return their argument or die.

=over 4

=item check_invocant($val)

=item check_maybe_invocant($val)

=item check_able($val, @method_names)

=item check_maybe_able($val, @method_names)

=item check_ref($val)

=item check_maybe_ref($val)

=item check_scalar_ref($val)

=item check_maybe_scalar_ref($val)

=item check_array_ref($val)

=item check_maybe_array_ref($val)

=item check_hash_ref($val)

=item check_maybe_hash_ref($val)

=item check_code_ref($val)

=item check_maybe_code_ref($val)

=item check_regex_ref($val)

=item check_maybe_regex_ref($val)

=item check_glob_ref($val)

=item check_maybe_glob_ref($val)

=item check_value($val)

=item check_maybe_value($val)

=item check_string($val)

=item check_maybe_string($val)

=item check_number($val)

=item check_maybe_number($val)

=item check_integer($val)

=item check_maybe_integer($val)

=item check_natural($val)

=item check_maybe_natural($val)

=item check_positive($val)

=item check_maybe_positive($val)

=item check_same($val, $other_val)

=item check_different($val, $other_val)

=back

=head2 Human output functions

    use Catmandu::Util qw(:human);

=over 4

=item human_number($num)

Insert a comma a 3-digit intervals to make C<$num> more readable. Only works
with I<integers> for now.

    human_number(64354);
    # => "64,354"

=item human_byte_size($size)

    human_byte_size(64);
    # => "64 bytes"
    human_byte_size(10005000);
    # => "10.01 MB"

=item human_content_type($content_type)

=item human_content_type($content_type, $default)

    human_content_type('application/x-dos_ms_excel');
    # => "Excel"
    human_content_type('application/zip');
    # => "ZIP archive"
    human_content_type('foo/x-unknown');
    # => "foo/x-unknown"
    human_content_type('foo/x-unknown', 'Unknown');
    # => "Unknown"

=back

=head2 XML functions

    use Catmandu::Util qw(:xml);

=over 4

=item xml_declaration()

Returns C<< qq(<?xml version="1.0" encoding="UTF-8"?>\n) >>.

=item xml_escape($str)

Returns an XML escaped copy of C<$str>.

=back

=head2 Miscellaneous functions

=over 4

=item require_package($pkg)

=item require_package($pkg, $namespace)

Load package C<$pkg> at runtime with C<require> and return it's full name.

    my $pkg = require_package('File::Spec');
    my $dir = $pkg->tmpdir();

    require_package('Util', 'Catmandu');
    # => "Catmandu::Util"
    require_package('Catmandu::Util', 'Catmandu');
    # => "Catmandu::Util"

=item use_lib(@dirs)

Add directories to C<@INC> at runtime.

=back

=head1 SEE ALSO

L<Data::Util>.

=cut

