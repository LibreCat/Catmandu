package Catmandu::Util;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Exporter qw(import);
use Sub::Quote    ();
use Scalar::Util  ();
use List::Util    ();
use Data::Util    ();
use Data::Compare ();
use IO::File;
use IO::Handle::Util ();
use File::Spec;
use YAML::XS            ();
use Cpanel::JSON::XS    ();
use Hash::Merge::Simple ();
use MIME::Types;
use POSIX       ();
use Time::HiRes ();

our %EXPORT_TAGS = (
    io => [
        qw(io read_file read_io write_file read_yaml read_json join_path
            normalize_path segmented_path content_type)
    ],
    data  => [qw(parse_data_path get_data set_data delete_data data_at)],
    array => [
        qw(array_exists array_group_by array_pluck array_to_sentence
            array_sum array_includes array_any array_rest array_uniq array_split)
    ],
    hash   => [qw(hash_merge)],
    string => [qw(as_utf8 trim capitalize)],
    is     => [qw(is_same is_different)],
    check  => [qw(check_same check_different)],
    human  => [qw(human_number human_content_type human_byte_size)],
    xml    => [qw(xml_declaration xml_escape)],
    misc   => [qw(require_package use_lib pod_section)],
    date   => [qw(now)],
);

our @EXPORT_OK = map {@$_} values %EXPORT_TAGS;

$EXPORT_TAGS{all} = \@EXPORT_OK;

my $HUMAN_CONTENT_TYPES = {

    # txt
    'text/plain'      => 'Text',
    'application/txt' => 'Text',

    # pdf
    'application/pdf'      => 'PDF',
    'application/x-pdf'    => 'PDF',
    'application/acrobat'  => 'PDF',
    'applications/vnd.pdf' => 'PDF',
    'text/pdf'             => 'PDF',
    'text/x-pdf'           => 'PDF',

    # doc
    'application/doc'         => 'Word',
    'application/vnd.msword'  => 'Word',
    'application/vnd.ms-word' => 'Word',
    'application/winword'     => 'Word',
    'application/word'        => 'Word',
    'application/x-msw6'      => 'Word',
    'application/x-msword'    => 'Word',

    # docx
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        => 'Word',

    # xls
    'application/vnd.ms-excel'   => 'Excel',
    'application/msexcel'        => 'Excel',
    'application/x-msexcel'      => 'Excel',
    'application/x-ms-excel'     => 'Excel',
    'application/vnd.ms-excel'   => 'Excel',
    'application/x-excel'        => 'Excel',
    'application/x-dos_ms_excel' => 'Excel',
    'application/xls'            => 'Excel',

    # xlsx
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' =>
        'Excel',

    # ppt
    'application/vnd.ms-powerpoint' => 'PowerPoint',
    'application/mspowerpoint'      => 'PowerPoint',
    'application/ms-powerpoint'     => 'PowerPoint',
    'application/mspowerpnt'        => 'PowerPoint',
    'application/vnd-mspowerpoint'  => 'PowerPoint',
    'application/powerpoint'        => 'PowerPoint',
    'application/x-powerpoint'      => 'PowerPoint',

    # pptx
    'application/vnd.openxmlformats-officedocument.presentationml.presentation'
        => 'PowerPoint',

    # csv
    'text/comma-separated-values' => 'CSV',
    'text/csv'                    => 'CSV',
    'application/csv'             => 'CSV',

    # zip
    'application/zip' => 'ZIP archive',
};

my $XML_DECLARATION = qq(<?xml version="1.0" encoding="UTF-8"?>\n);

sub TIESCALAR { }

sub io {
    my ($arg, %opts) = @_;
    my $binmode = $opts{binmode} || $opts{encoding} || ':encoding(UTF-8)';
    my $mode    = $opts{mode}    || 'r';
    my $io;

    if (is_scalar_ref($arg)) {
        $io = IO::Handle::Util::io_from_scalar_ref($arg);
        defined($io) && binmode $io, $binmode;
    }
    elsif (is_glob_ref(\$arg) || is_glob_ref($arg)) {
        $io = IO::Handle->new_from_fd($arg, $mode) // $arg;
        defined($io) && binmode $io, $binmode;
    }
    elsif (is_string($arg)) {
        $io = IO::File->new($arg, $mode);
        defined($io) && binmode $io, $binmode;
    }
    elsif (is_code_ref($arg) && $mode eq 'r') {
        $io = IO::Handle::Util::io_from_getline($arg);
    }
    elsif (is_code_ref($arg) && $mode eq 'w') {
        $io = IO::Handle::Util::io_from_write_cb($arg);
    }
    elsif (is_instance($arg, 'IO::Handle')) {
        $io = $arg;
        defined($io) && binmode $io, $binmode;
    }
    else {
        Catmandu::BadArg->throw("can't make io from argument");
    }

    $io;
}

# Deprecated use tools like File::Slurp::Tiny
sub read_file {
    my ($path) = @_;
    local $/;
    open my $fh, "<:encoding(UTF-8)", $path
        or Catmandu::Error->throw(qq(can't open "$path" for reading));
    my $str = <$fh>;
    close $fh;
    $str;
}

sub read_io {
    my ($io) = @_;
    $io->binmode("encoding(UTF-8)") if ($io->can('binmode'));
    my @lines = ();
    while (<$io>) {
        push @lines, $_;
    }
    $io->close();
    join "", @lines;
}

# Deprecated use tools like File::Slurp::Tiny
sub write_file {
    my ($path, $str) = @_;
    open my $fh, ">:encoding(UTF-8)", $path
        or Catmandu::Error->throw(qq(can't open "$path" for writing));
    print $fh $str;
    close $fh;
    $path;
}

sub read_yaml {

    # dies on error
    YAML::XS::LoadFile($_[0]);
}

sub read_json {
    my $text = read_file($_[0]);

    # dies on error
    Cpanel::JSON::XS->new->decode($text);
}

##
# Split a path on . or /, but not on \/ or \.
sub split_path {
    my ($path) = @_;
    $path = trim($path);
    $path =~ s/^\$[\.\/]//;
    return [map {s/\\(?=[\.\/])//g; $_} split /(?<!\\)[\.\/]/, $path];
}

sub join_path {
    my $path = File::Spec->catfile(@_);
    $path =~ s!/\./!/!g;
    while ($path =~ s![^/]*/\.\./!!) { }
    $path;
}

sub normalize_path {    # taken from Dancer::FileUtils
    my ($path) = @_;
    $path =~ s!/\./!/!g;
    while ($path =~ s![^/]*/\.\./!!) { }
    File::Spec->catfile($path);
}

sub segmented_path {
    my ($id, %opts) = @_;
    my $segment_size = $opts{segment_size} || 3;
    my $base_path    = $opts{base_path};
    $id =~ s/[^0-9a-zA-Z]+//g;
    my @path = unpack "(A$segment_size)*", $id;
    defined $base_path
        ? File::Spec->catdir($base_path, @path)
        : File::Spec->catdir(@path);
}

my $MIME_TYPES;

sub content_type {
    my ($filename) = @_;

    $MIME_TYPES ||= MIME::Types->new(only_complete => 1);

    return undef unless $filename;

    my ($ext) = $filename =~ /\.(.+?)$/;

    my $type = 'application/octet-stream';

    my $mime = $MIME_TYPES->mimeTypeOf($ext);

    # Require explicit stringification!
    $type = sprintf "%s", $mime->type if $mime;

    $type;
}

sub parse_data_path {
    my ($path) = @_;
    check_string($path);
    $path = split_path($path);
    my $key = pop @$path;
    return $path, $key;
}

sub get_data {
    my ($data, $key) = @_;
    if (is_array_ref($data)) {
        if    ($key eq '$first') {return unless @$data; $key = 0}
        elsif ($key eq '$last')  {return unless @$data; $key = @$data - 1}
        elsif ($key eq '*')      {return @$data}
        if    (array_exists($data, $key)) {
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
        if    ($key eq '$first') {return unless @$data; $key = 0}
        elsif ($key eq '$last')  {return unless @$data; $key = @$data - 1}
        elsif ($key eq '$prepend') {
            unshift @$data, $vals[0];
            return $vals[0];
        }
        elsif ($key eq '$append') {push @$data, $vals[0]; return $vals[0]}
        elsif ($key eq '*') {return splice @$data, 0, @$data, @vals}
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
        if    ($key eq '$first') {return unless @$data; $key = 0}
        elsif ($key eq '$last')  {return unless @$data; $key = @$data - 1}
        elsif ($key eq '*')      {return splice @$data, 0, @$data}
        if    (array_exists($data, $key)) {
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
    if (ref $path) {
        $path = [map {split_path($_)} @$path];
    }
    else {
        $path = split_path($path);
    }
    my $create = $opts{create};
    my $_key   = $opts{_key} // $opts{key};
    if (defined $opts{key} && $create && @$path) {
        push @$path, $_key;
    }
    my $key;
    while (defined(my $key = shift @$path)) {
        is_ref($data) || return;
        if (is_array_ref($data)) {
            if ($key eq '*') {
                return
                    map {data_at($path, $_, create => $create, _key => $_key)}
                    @$data;
            }
            else {
                if    ($key eq '$first')   {$key = 0}
                elsif ($key eq '$last')    {$key = -1}
                elsif ($key eq '$prepend') {unshift @$data, undef; $key = 0}
                elsif ($key eq '$append')  {push @$data, undef; $key = @$data}
                is_integer($key) || return;
                if ($create && @$path) {
                    $data = $data->[$key] ||= is_integer($path->[0])
                        || ord($path->[0]) == ord('$') ? [] : {};
                }
                else {
                    $data = $data->[$key];
                }
            }
        }
        elsif ($create && @$path) {
            $data = $data->{$key} ||= is_integer($path->[0])
                || ord($path->[0]) == ord('$') ? [] : {};
        }
        else {
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
    List::Util::reduce {
        my $k = $b->{$key};
        push @{$a->{$k} ||= []}, $b if defined $k;
        $a
    }
    {}, @$arr;
}

sub array_pluck {
    my ($arr, $key) = @_;
    my @vals = map {$_->{$key}} @$arr;
    \@vals;
}

sub array_to_sentence {
    my ($arr, $join, $join_last) = @_;
    $join      //= ', ';
    $join_last //= ' and ';
    my $size = scalar @$arr;
    $size > 2
        ? join($join_last, join($join, @$arr[0 .. $size - 2]), $arr->[-1])
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
    @$arr < 2 ? [] : [@$arr[1 .. (@$arr - 1)]];
}

sub array_uniq {
    my ($arr) = @_;
    my %seen  = ();
    my @vals  = grep {not $seen{$_}++} @$arr;
    \@vals;
}

sub array_split {
    my ($arr) = @_;
    is_array_ref($arr) ? $arr : [split ',', $arr];
}

sub as_utf8 {
    my $str = $_[0];
    utf8::upgrade($str);
    $str;
}

sub trim {
    my $str = $_[0];
    if ($str) {
        $str =~ s/^[\h\v]+//s;
        $str =~ s/[\h\v]+$//s;
    }
    $str;
}

sub capitalize {
    my $str = $_[0];
    utf8::upgrade($str);
    ucfirst lc $str;
}

sub is_different {
    !is_same(@_);
}

sub check_same {
    is_same(@_) || Catmandu::BadVal->throw('should be same');
    $_[0];
}

sub check_different {
    is_same(@_) && Catmandu::BadVal->throw('should be different');
    $_[0];
}

sub is_bool {
    Scalar::Util::blessed($_[0])
        && ($_[0]->isa('boolean')
        || $_[0]->isa('Types::Serialiser::Boolean')
        || $_[0]->isa('JSON::XS::Boolean')
        || $_[0]->isa('Cpanel::JSON::XS::Boolean')
        || $_[0]->isa('JSON::PP::Boolean'));
}

sub is_integer {
    Data::Util::is_integer($_[0]) && $_[0] !~ /^0[0-9]/;
}

sub is_natural {
    is_integer($_[0]) && $_[0] >= 0;
}

sub is_positive {
    is_integer($_[0]) && $_[0] >= 1;
}

sub is_float {
    is_value($_[0])
        && $_[0] =~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/
        && $_[0] !~ /^0[0-9]/;
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
    Catmandu::BadVal->throw('should be able to ' . array_to_sentence(\@_));
}

sub check_maybe_able {
    my $obj = shift;
    return $obj if is_maybe_able($obj, @_);
    Catmandu::BadVal->throw(
        'should be undef or able to ' . array_to_sentence(\@_));
}

sub is_instance {
    my $obj = shift;
    Scalar::Util::blessed($obj) || return 0;
    $obj->isa($_)               || return 0 for @_;
    1;
}

sub check_instance {
    my $obj = shift;
    return $obj if is_instance($obj, @_);
    Catmandu::BadVal->throw(
        'should be instance of ' . array_to_sentence(\@_));
}

sub check_maybe_instance {
    my $obj = shift;
    return $obj if is_maybe_instance($obj, @_);
    Catmandu::BadVal->throw(
        'should be undef or instance of ' . array_to_sentence(\@_));
}

Data::Util::install_subroutine(
    __PACKAGE__,
    hash_merge    => \&Hash::Merge::Simple::merge,
    is_same       => \&Data::Compare::Compare,
    is_invocant   => \&Data::Util::is_invocant,
    is_scalar_ref => \&Data::Util::is_scalar_ref,
    is_array_ref  => \&Data::Util::is_array_ref,
    is_hash_ref   => \&Data::Util::is_hash_ref,
    is_code_ref   => \&Data::Util::is_code_ref,
    is_regex_ref  => \&Data::Util::is_rx,
    is_glob_ref   => \&Data::Util::is_glob_ref,
    is_value      => \&Data::Util::is_value,
    is_string     => \&Data::Util::is_string,
    is_number     => \&Data::Util::is_number,
);

for my $sym (
    qw(able instance invocant ref
    scalar_ref array_ref hash_ref code_ref regex_ref glob_ref
    bool value string number integer natural positive float)
    )
{
    my $err_name = $sym;
    $err_name =~ s/_/ /;

    push @EXPORT_OK, "is_$sym", "is_maybe_$sym", "check_$sym",
        "check_maybe_$sym";
    push @{$EXPORT_TAGS{is}},    "is_$sym",    "is_maybe_$sym";
    push @{$EXPORT_TAGS{check}}, "check_$sym", "check_maybe_$sym";

    unless (Data::Util::get_code_ref(__PACKAGE__, "is_maybe_$sym")) {
        my $sub
            = Sub::Quote::quote_sub("!defined(\$_[0]) || is_$sym(\$_[0])");
        Data::Util::install_subroutine(__PACKAGE__, "is_maybe_$sym" => $sub);
    }

    unless (Data::Util::get_code_ref(__PACKAGE__, "check_$sym")) {
        my $sub
            = Sub::Quote::quote_sub(
            "is_$sym(\$_[0]) || Catmandu::BadVal->throw('should be $err_name'); \$_[0]"
            );
        Data::Util::install_subroutine(__PACKAGE__, "check_$sym" => $sub);
    }

    unless (Data::Util::get_code_ref(__PACKAGE__, "check_maybe_$sym")) {
        my $sub
            = Sub::Quote::quote_sub(
            "is_maybe_$sym(\$_[0]) || Catmandu::BadVal->throw('should be undef or $err_name'); \$_[0]"
            );
        Data::Util::install_subroutine(__PACKAGE__,
            "check_maybe_$sym" => $sub);
    }
}

sub human_number {    # taken from Number::Format
    my $num = $_[0];

    # add leading 0's so length($num) is divisible by 3
    $num = '0' x (3 - (length($num) % 3)) . $num;

    # split $num into groups of 3 characters and insert commas
    $num = join ',', grep {$_ ne ''} split /(...)/, $num;

    # strip off leading zeroes and/or comma
    $num =~ s/^0+,?//;
    length $num ? $num : '0';
}

sub human_byte_size {
    my ($size) = @_;
    if ($size > 1000000000) {
        return sprintf("%.2f GB", $size / 1000000000);
    }
    elsif ($size > 1000000) {
        return sprintf("%.2f MB", $size / 1000000);
    }
    elsif ($size > 1000) {
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
    $str
        =~ s/[^\x09\x0A\x0D\x20-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]//go;

    $str;
}

sub use_lib {
    my (@dirs) = @_;

    use lib;
    local $@;
    lib->import(@dirs);
    Catmandu::Error->throw($@) if $@;

    1;
}

sub pod_section {
    my $class   = is_ref($_[0]) ? ref(shift) : shift;
    my $section = uc(shift);

    unless (-r $class) {
        $class =~ s!::!/!g;
        $class .= '.pm';
        $class = $INC{$class} or return '';
    }

    my $text = "";
    open my $input,  "<", $class or return '';
    open my $output, ">", \$text;

    require Pod::Usage;    # lazy load only if needed
    Pod::Usage::pod2usage(
        -input    => $input,
        -output   => $output,
        -sections => $section,
        -exit     => "NOEXIT",
        -verbose  => 99,
        -indent   => 0,
        -utf8     => 1,
        @_
    );
    $section = ucfirst(lc($section));
    $text =~ s/$section:\n//m;
    chomp $text;

    $text;
}

sub require_package {
    my ($pkg, $ns) = @_;

    if ($ns) {
        unless ($pkg =~ s/^\+// || $pkg =~ /^$ns/) {
            $pkg = "${ns}::$pkg";
        }
    }

    return $pkg if is_invocant($pkg);

    eval "require $pkg;1;"
        or Catmandu::NoSuchPackage->throw(
        message      => "No such package: $pkg",
        package_name => $pkg
        );

    $pkg;
}

sub now {
    my $format = $_[0];
    my $now;

    if (!defined $format || $format eq 'iso_date_time') {
        $now = POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', gmtime(time));
    }
    elsif ($format eq 'iso_date_time_millis') {
        my $t = Time::HiRes::time;
        $now = POSIX::strftime('%Y-%m-%dT%H:%M:%S', gmtime($t));
        $now .= sprintf('.%03d', ($t - int($t)) * 1000);
        $now .= 'Z';
    }
    else {
        $now = POSIX::strftime($format, gmtime(time));
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

[deprecated]: use tools like Path::Tiny instead.

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

=item content_type($filename);

Guess the content type of a file name.

    content_type("book.pdf");
    # => "application/pdf"

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

Returns a copy of C<$array> with all duplicates removed.

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

=item is_float($val)

=item is_maybe_float($val)

Tests if C<$val> is a floating point number.

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

=item check_float($val)

=item check_maybe_float($val)

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

=item now($format)

Returns the current datetime as a string. C<$format>can be any
C<strftime> format. There are also 2 builtin formats, C<iso_date_time>
and C<iso_date_time_millis>.  C<iso_date_time> is equivalent to
C<%Y-%m-%dT%H:%M:%SZ>. C<iso_date_time_millis> is the same, but with
added milliseconds.

    now('%Y/%m/%d');
    now('iso_date_time_millis');

The default format is C<iso_date_time>;

=back

=cut
