package Catmandu::Util;

use Catmandu::Sane;

our $VERSION = '1.0201_02';

use parent 'Exporter';

our %EXPORT_TAGS = (
    array => [
        qw(array_exists array_group_by array_pluck array_to_sentence
            array_sum array_includes array_any array_rest array_uniq array_split)
    ],
    check => [qw(check_same check_different)],
    data  => [qw(parse_data_path get_data set_data delete_data data_at)],
    hash  => [qw(hash_merge)],
    human => [qw(human_number human_content_type human_byte_size)],
    io    => [
        qw(io read_file read_io write_file read_yaml read_json join_path
            normalize_path segmented_path)
    ],
    is     => [qw(is_same is_different)],
    misc   => [qw(require_package use_lib pod_section)],
    string => [qw(as_utf8 trim capitalize)],
    xml    => [qw(xml_declaration xml_escape)],
);

my @TYPES = qw(able instance invocant ref
    scalar_ref array_ref hash_ref code_ref regex_ref glob_ref
    bool value string number integer natural positive);

for (@TYPES) {
    push @{$EXPORT_TAGS{is}},    "is_$_",    "is_maybe_$_";
    push @{$EXPORT_TAGS{check}}, "check_$_", "check_maybe_$_";
}

our @EXPORT_OK = map {@$_} values %EXPORT_TAGS;

$EXPORT_TAGS{all} = \@EXPORT_OK;

my %SYM_INDEX = (
    require_package => 'Package',
    use_lib         => 'Package',
    pod_section     => 'Pod',
    check_different => 'Compare',
    check_same      => 'Compare',
    is_different    => 'Compare',
    is_same         => 'Compare',
);
$SYM_INDEX{$_} = 'Array'  for @{$EXPORT_TAGS{array}};
$SYM_INDEX{$_} = 'Data'   for @{$EXPORT_TAGS{data}};
$SYM_INDEX{$_} = 'Hash'   for @{$EXPORT_TAGS{hash}};
$SYM_INDEX{$_} = 'Human'  for @{$EXPORT_TAGS{human}};
$SYM_INDEX{$_} = 'IO'     for @{$EXPORT_TAGS{io}};
$SYM_INDEX{$_} = 'String' for @{$EXPORT_TAGS{string}};
$SYM_INDEX{$_} ||= 'Type' for @{$EXPORT_TAGS{check}};
$SYM_INDEX{$_} ||= 'Type' for @{$EXPORT_TAGS{is}};
$SYM_INDEX{$_} = 'XML' for @{$EXPORT_TAGS{xml}};

my %TAG_INDEX = (
    ':all' => [
        [qw(Array Compare Data Hash Human IO Package Pod String Type XML)],
        ':all'
    ],
    ':array'  => [[qw(Array)],        ':all'],
    ':check'  => [[qw(Compare Type)], ':check'],
    ':data'   => [[qw(Data)],         ':all'],
    ':hash'   => [[qw(Hash)],         ':all'],
    ':human'  => [[qw(Human)],        ':all'],
    ':is'     => [[qw(Compare Type)], ':is'],
    ':io'     => [[qw(IO)],           ':all'],
    ':misc'   => [[qw(Package Pod)],  ':all'],
    ':string' => [[qw(String)],       ':all'],
    ':xml'    => [[qw(XML)],          ':all'],
);

sub import {
    shift;
    my %pkgs;
    for my $sym (@_) {
        if (my $pkg = $SYM_INDEX{$sym}) {
            push @{$pkgs{$pkg} ||= []}, $sym;
        }
        elsif (my $spec = $TAG_INDEX{$sym}) {
            push @{$pkgs{$_} ||= []}, $spec->[1] for @{$spec->[0]};
        }
        else {
            Catmandu::BadVal->throw("$sym is not exported by " . __PACKAGE__);
        }
    }

    for (keys %pkgs) {
        my $pkg = __PACKAGE__ . "::$_";
        require $pkg;
        $pkg->export_to_level(1, __PACKAGE__, @{$pkgs{$pkg}});
    }
}

1;

__END__

=pod

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

    my $write_cb = sub { my $str = $_[0]; ... };

    my $fh = io $write_cb, mode => 'w';

    my $scalar = "";
    my $fh = io \$scalar, mode => 'w';
    $fh->print("some text");

Options are:

=over 12

=item mode

Default is C<"r">.

=item binmode

Default is C<":encoding(UTF-8)">.

=item encoding

Alias for C<binmode>.

=back

=item read_file($path);

[deprecated]: use tools like use tools like File::Slurp::Tiny instead.

Reads the file at C<$path> into a string.

    my $str = read_file('/path/to/file.txt');

Throws a Catmandu::Error on failure. 

=item read_io($io)

Reads an IO::Handle into a string.

   my $str = read_file($fh);

=item write_file($path, $str);

[deprecated]: use tools like use tools like File::Slurp::Tiny instead.

Writes the string C<$str> to a file at C<$path>.

    write_file('/path/to/file.txt', "contents");

Throws a Catmandu::Error on failure. 

=item read_yaml($path);

Reads the YAML file at C<$path> into a Perl hash.

    my $cfg = read_yaml($path);

Dies on failure reading the file or parsing the YAML.

=item read_json($path);

Reads the JSON file at C<$path> into a Perl hash.

    my $cfg = read_json($path);

Dies on failure reading the file or parsing the JSON.

=item join_path(@path);

Joins relative paths into an absolute path.

    join_path('/path/..', './to', 'file.txt');
    # => "/to/file.txt"

=item normalize_path($path);

Normalizes a relative path to an absolute path.

    normalize_path('/path/../to/./file.txt');
    # => "/to/file.txt"

=item segmented_path($path);

    my $id = "FB41144C-F0ED-11E1-A9DE-61C894A0A6B4";
    segmented_path($id, segment_size => 4);
    # => "FB41/144C/F0ED/11E1/A9DE/61C8/94A0/A6B4"
    segmented_path($id, segment_size => 2, base_path => "/files");
    # => "/files/FB/41/14/4C/F0/ED/11/E1/A9/DE/61/C8/94/A0/A6/B4"

=back

=head2 Hash functions

    use Catmandu::Util qw(:hash);

A collection of functions that operate on hash references.

=over 4

=item hash_merge($hash1, $hash2, ... , $hashN)

Merge <hash1> through <hashN>,  with the nth-most (rightmost) hash taking precedence.
Returns a new hash reference representing the merge.

    hash_merge({a => 1}, {b => 2}, {a => 3});
    # => { a => 3 , b => 2}

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

=item array_split($array | $string)

Returns C<$array> or a new array by splitting C<$string> at commas. 

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

=item is_instance($val, @class_names)

=item is_maybe_instance($val, @class_names)

Tests if C<$val> is a blessed object and an instance of all the classes
in C<@class_names>.

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

=item check_instance($val, @class_names)

=item check_maybe_instance($val, @class_names)

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

Throws a Catmandu::Error on failure.

=item use_lib(@dirs)

Add directories to C<@INC> at runtime.

Throws a Catmandu::Error on failure.

=item pod_section($package_or_file, $section [, @options] )

Get documentation of a package for a selected section. Additional options are
passed to L<Pod::Usage>.

=back

=cut
