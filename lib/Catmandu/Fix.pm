package Catmandu::Fix;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Moo;
use Catmandu::Fix::Parser;
use Text::Hogan::Compiler;
use Path::Tiny ();
use File::Spec ();
use File::Temp ();
use Catmandu::Util qw(
    is_string
    is_array_ref
    is_hash_ref
    is_code_ref
    is_glob_ref
    is_instance
    is_able
    require_package
);
use namespace::clean;

with 'Catmandu::Logger';
with 'Catmandu::Emit';

has parser => (is => 'lazy');
has fixer  => (is => 'lazy', init_arg => undef);
has _captures =>
    (is => 'ro', lazy => 1, init_arg => undef, default => sub {+{}});
has var =>
    (is => 'ro', lazy => 1, init_arg => undef, builder => '_generate_var');
has _fixes => (is => 'ro', init_arg => 'fixes', default => sub {[]});
has fixes =>
    (is => 'ro', lazy => 1, init_arg => undef, builder => '_build_fixes');
has _reject_var => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_reject_var'
);
has _fixes_var => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_fixes_var'
);
has preprocess => (is => 'ro');
has _hogan =>
    (is => 'ro', lazy => 1, init_arg => undef, builder => '_build_hogan');
has _hogan_vars => (is => 'ro', init_arg => 'variables');

sub _build_parser {
    Catmandu::Fix::Parser->new;
}

sub _build_fixes {
    my ($self)    = @_;
    my $fixes_arg = $self->_fixes;
    my $fixes     = [];

    for my $fix (@$fixes_arg) {

        if (is_code_ref($fix)) {
            push @$fixes, require_package('Catmandu::Fix::code')->new($fix);
        }
        elsif (ref $fix && ref($fix) =~ /^IO::/) {
            my $txt = Catmandu::Util::read_io($fix);
            $txt = $self->_preprocess($txt);
            push @$fixes, @{$self->parser->parse($txt)};
        }
        elsif (is_glob_ref($fix)) {
            my $fh  = Catmandu::Util::io($fix, binmode => ':encoding(UTF-8)');
            my $txt = Catmandu::Util::read_io($fh);
            $txt = $self->_preprocess($txt);
            push @$fixes, @{$self->parser->parse($txt)};
        }
        elsif (ref $fix) {
            push @$fixes, $fix;
        }
        elsif (is_string($fix)) {
            if ($fix =~ /[^\s]/ && $fix !~ /\(/) {
                $fix = Path::Tiny::path($fix)->slurp_utf8;
            }
            $fix = $self->_preprocess($fix);
            push @$fixes, @{$self->parser->parse($fix)};
        }
    }

    $fixes;
}

sub _build_fixer {
    my ($self) = @_;

    my $reject = $self->_reject;
    my $sub    = $self->_eval_sub(
        $self->emit,
        args     => [$self->var],
        captures => $self->_captures
    );

    sub {
        my $data = $_[0];

        if (is_hash_ref($data)) {
            my $d = $sub->($data);
            return if ref $d && $d == $reject;
            return $d;
        }

        if (is_array_ref($data)) {
            return [grep {!(ref $_ && $_ == $reject)}
                    map {$sub->($_)} @$data];
        }

        if (is_code_ref($data)) {
            return sub {
                while (1) {
                    my $d = $sub->($data->() // return);
                    return if ref $d && $d == $reject;
                    return $d;
                }
            };
        }

        if (   is_instance($data)
            && is_able($data, 'does')
            && $data->does('Catmandu::Iterable'))
        {
            return $data->map(sub {$sub->($_[0])})
                ->reject(sub {ref $_[0] && $_[0] == $reject});
        }

        Catmandu::BadArg->throw(
            "must be hashref, arrayref, coderef or iterable object");
    };
}

sub _build_reject_var {
    my ($self) = @_;
    $self->capture($self->_reject);
}

sub _build_fixes_var {
    my ($self) = @_;
    $self->capture($self->fixes);
}

sub _build_hogan {
    Text::Hogan::Compiler->new;
}

sub _preprocess {
    my ($self, $text) = @_;
    return $text unless $self->preprocess || $self->_hogan_vars;
    my $vars = $self->_hogan_vars         || {};
    $self->_hogan->compile($text, {numeric_string_as_string => 1})
        ->render($vars);
}

sub fix {
    my ($self, $data) = @_;
    $self->fixer->($data);
}

sub generate_var {
    $_[0]->_generate_var;
}

sub generate_label {
    $_[0]->_generate_label;
}

sub capture {
    my ($self, $capture) = @_;
    my $var = $self->_generate_var;
    $self->_captures->{$var} = $capture;
    $var;
}

sub emit {
    my ($self)     = @_;
    my $var        = $self->var;
    my $err        = $self->_generate_var;
    my $reject_var = $self->_reject_var;
    my $perl       = "";

    $perl .= "eval {";

    # Loop over all the fixes and emit their code
    $perl .= $self->emit_fixes($self->fixes);

    $perl .= "return ${var};";
    $perl .= $self->_reject_label . ": return ${reject_var};";
    $perl .= "} or do {";
    $perl .= $self->_emit_declare_vars($err, '$@');
    $perl .= "${err}->throw if is_instance(${err},'Throwable::Error');";
    $perl .= "Catmandu::FixError->throw(message => ${err}, data => ${var});";
    $perl .= "};";

    $self->log->debug($perl);

    $perl;
}

# Emit an array of fixes
sub emit_fixes {
    my ($self, $fixes) = @_;
    my $perl = '';

    for (my $i = 0; $i < @{$fixes}; $i++) {
        my $fix = $fixes->[$i];
        $perl .= $self->emit_fix($fix);
    }

    $perl;
}

sub emit_reject {
    $_[0]->_emit_reject;
}

sub emit_fix {
    my ($self, $fix) = @_;
    my $perl;

    if ($fix->can('emit')) {
        $perl = $self->emit_block(
            sub {
                my ($label) = @_;
                $fix->emit($self, $label);
            }
        );
    }
    elsif ($fix->can('fix')) {
        my $var = $self->var;
        my $ref = $self->_generate_var;
        $self->_captures->{$ref} = $fix;
        $perl = "${var} = ${ref}->fix(${var});";
    }
    else {
        Catmandu::Error->throw('not a fix');
    }

    $perl;
}

sub emit_block {
    my ($self, $cb) = @_;
    my $label = $self->_generate_label;
    my $perl  = "${label}: {";
    $perl .= $cb->($label);
    $perl .= "};";
    $perl;
}

sub emit_clear_hash_ref {
    my ($self, $var) = @_;
    "undef %{${var}} if is_hash_ref(${var});";
}

sub emit_value {
    shift->_emit_value(@_);
}

sub emit_string {
    shift->_emit_string(@_);
}

sub emit_match {
    my ($self, $pattern) = @_;
    $pattern =~ s/\//\\\//g;
    $pattern =~ s/\\$/\\\\/;    # pattern can't end with an escape in m/.../
    "m/$pattern/";
}

sub emit_substitution {
    my ($self, $pattern, $replace) = @_;
    $pattern =~ s/\//\\\//g;
    $pattern =~ s/\\$/\\\\/;    # pattern can't end with an escape in m/.../
    $replace =~ s/\//\\\//g;
    $replace =~ s/\\$/\\\\/;    # pattern can't end with an escape in m/.../
    "s/$pattern/$replace/";
}

sub emit_declare_vars {
    shift->_emit_declare_vars(@_);
}

sub emit_new_scope {
    "{";
}

sub emit_end_scope {
    "};";
}

sub emit_foreach {
    my ($self, $var, $cb) = @_;
    my $perl = "";
    my $v    = $self->_generate_var;
    $perl .= "foreach (\@{${var}}) {";
    $perl .= $self->emit_declare_vars($v, '$_');
    $perl .= $cb->($v);
    $perl .= "}";
    $perl;
}

sub emit_foreach_key {
    my ($self, $var, $cb) = @_;
    my $perl = "";
    my $v    = $self->_generate_var;
    $perl .= "foreach (keys(\%{${var}})) {";
    $perl .= $self->emit_declare_vars($v, '$_');
    $perl .= $cb->($v);
    $perl .= "}";
    $perl;
}

sub emit_walk_path {
    my ($self, $var, $keys, $cb) = @_;

    $keys = [@$keys];    # protect keys

    if (@$keys) {        # protect $var
        my $v = $self->_generate_var;
        $self->_emit_declare_vars($v, $var)
            . $self->_emit_walk_path($v, $keys, $cb);
    }
    else {
        $cb->($var);
    }
}

sub _emit_walk_path {
    my ($self, $var, $keys, $cb) = @_;

    @$keys || return $cb->($var);

    my $key     = shift @$keys;
    my $str_key = $self->emit_string($key);
    my $perl    = "";

    if ($key =~ /^[0-9]+$/) {
        $perl .= "if (is_hash_ref(${var})) {";
        $perl .= "${var} = ${var}->{${str_key}};";
        $perl .= $self->_emit_walk_path($var, [@$keys], $cb);
        $perl .= "} elsif (is_array_ref(${var}) && \@{${var}} > ${key}) {";
        $perl .= "${var} = ${var}->[${key}];";
        $perl .= $self->_emit_walk_path($var, [@$keys], $cb);
        $perl .= "}";
    }
    elsif ($key eq '*') {
        my $v = $self->_generate_var;
        $perl .= "if (is_array_ref(${var})) {";
        $perl .= $self->emit_foreach(
            $var,
            sub {
                return $self->_emit_walk_path(shift, $keys, $cb);
            }
        );
        $perl .= "}";
    }
    else {
        if ($key eq '$first') {
            $perl .= "if (is_array_ref(${var}) && \@{${var}}) {";
            $perl .= "${var} = ${var}->[0];";
        }
        elsif ($key eq '$last') {
            $perl .= "if (is_array_ref(${var}) && \@{${var}}) {";
            $perl .= "${var} = ${var}->[\@{${var}} - 1];";
        }
        else {
            $perl .= "if (is_hash_ref(${var})) {";
            $perl .= "${var} = ${var}->{${str_key}};";
        }
        $perl .= $self->_emit_walk_path($var, $keys, $cb);
        $perl .= "}";
    }

    $perl;
}

sub emit_create_path {
    my ($self, $var, $keys, $cb) = @_;
    $self->_emit_create_path($var, [@$keys], $cb);
}

sub _emit_create_path {
    my ($self, $var, $keys, $cb) = @_;

    @$keys || return $cb->($var);

    my $key     = shift @$keys;
    my $str_key = $self->emit_string($key);
    my $perl    = "";

    if ($key =~ /^[0-9]+$/) {
        my $v1 = $self->_generate_var;
        my $v2 = $self->_generate_var;
        $perl .= "if (is_hash_ref(${var})) {";
        $perl .= "my ${v1} = ${var};";
        $perl
            .= $self->_emit_create_path("${v1}->{${str_key}}", [@$keys], $cb);
        $perl .= "} elsif (is_maybe_array_ref(${var})) {";
        $perl .= "my ${v2} = ${var} //= [];";
        $perl .= $self->_emit_create_path("${v2}->[${key}]", [@$keys], $cb);
        $perl .= "}";
    }
    elsif ($key eq '*') {
        my $v1 = $self->_generate_var;
        my $v2 = $self->_generate_var;
        $perl .= "if (is_array_ref(${var})) {";
        $perl .= "my ${v1} = ${var};";
        $perl .= "for (my ${v2} = 0; ${v2} < \@{${v1}}; ${v2}++) {";
        $perl .= $self->_emit_create_path("${v1}->[${v2}]", $keys, $cb);
        $perl .= "}";
        $perl .= "}";
    }
    else {
        my $v = $self->_generate_var;
        if (   $key eq '$first'
            || $key eq '$last'
            || $key eq '$prepend'
            || $key eq '$append')
        {
            $perl .= "if (is_maybe_array_ref(${var})) {";
            $perl .= "my ${v} = ${var} //= [];";
            if ($key eq '$first') {
                $perl .= $self->_emit_create_path("${v}->[0]", $keys, $cb);
            }
            elsif ($key eq '$last') {
                $perl .= "if (\@${v}) {";
                $perl .= $self->_emit_create_path("${v}->[\@${v} - 1]",
                    [@$keys], $cb);
                $perl .= "} else {";
                $perl .= $self->_emit_create_path("${v}->[0]", [@$keys], $cb);
                $perl .= "}";
            }
            elsif ($key eq '$prepend') {
                $perl .= "if (\@${v}) {";
                $perl .= "unshift(\@${v}, undef);";
                $perl .= "}";
                $perl .= $self->_emit_create_path("${v}->[0]", $keys, $cb);
            }
            elsif ($key eq '$append') {
                $perl
                    .= $self->_emit_create_path("${v}->[\@${v}]", $keys, $cb);
            }
            $perl .= "}";
        }
        else {
            $perl .= "if (is_maybe_hash_ref(${var})) {";
            $perl .= "my ${v} = ${var} //= {};";
            $perl
                .= $self->_emit_create_path("${v}->{${str_key}}", $keys, $cb);
            $perl .= "}";
        }
    }

    $perl;
}

sub emit_get_key {
    my ($self, $var, $key, $cb) = @_;

    return $cb->($var) unless defined $key;

    my $str_key = $self->emit_string($key);
    my $perl    = "";

    if ($key =~ /^[0-9]+$/) {
        $perl .= "if (is_hash_ref(${var}) && exists(${var}->{${str_key}})) {";
        $perl .= $cb->("${var}->{${str_key}}");
        $perl .= "} elsif (is_array_ref(${var}) && \@{${var}} > ${key}) {";
        $perl .= $cb->("${var}->[${key}]");
        $perl .= "}";
    }
    elsif ($key eq '$first') {
        $perl .= "if (is_array_ref(${var}) && \@{${var}}) {";
        $perl .= $cb->("${var}->[0]");
        $perl .= "}";
    }
    elsif ($key eq '$last') {
        $perl .= "if (is_array_ref(${var}) && \@{${var}}) {";
        $perl .= $cb->("${var}->[\@{${var}} - 1]");
        $perl .= "}";
    }
    elsif ($key eq '*') {
        my $i = $self->_generate_var;
        $perl .= "if (is_array_ref(${var})) {";
        $perl .= "for (my ${i} = 0; ${i} < \@{${var}}; ${i}++) {";
        $perl .= $cb->("${var}->[${i}]", $i);
        $perl .= "}}";
    }
    else {
        $perl .= "if (is_hash_ref(${var}) && exists(${var}->{${str_key}})) {";
        $perl .= $cb->("${var}->{${str_key}}");
        $perl .= "}";
    }

    $perl;
}

sub emit_set_key {
    my ($self, $var, $key, $val) = @_;

    return "${var} = $val;" unless defined $key;

    my $perl    = "";
    my $str_key = $self->emit_string($key);

    if ($key =~ /^[0-9]+$/) {
        $perl .= "if (is_hash_ref(${var})) {";
        $perl .= "${var}->{${str_key}} = $val;";
        $perl .= "} elsif (is_array_ref(${var})) {";
        $perl .= "${var}->[${key}] = $val;";
        $perl .= "}";
    }
    elsif ($key eq '$first') {
        $perl .= "if (is_array_ref(${var})) {";
        $perl .= "${var}->[0] = $val;";
        $perl .= "}";
    }
    elsif ($key eq '$last') {
        $perl .= "if (is_array_ref(${var})) {";
        $perl .= "${var}->[\@{${var}} - 1] = $val;";
        $perl .= "}";
    }
    elsif ($key eq '$prepend') {
        $perl .= "if (is_array_ref(${var})) {";
        $perl .= "unshift(\@{${var}}, $val);";
        $perl .= "}";
    }
    elsif ($key eq '$append') {
        $perl .= "if (is_array_ref(${var})) {";
        $perl .= "push(\@{${var}}, $val);";
        $perl .= "}";
    }
    elsif ($key eq '*') {
        my $i = $self->_generate_var;
        $perl .= "if (is_array_ref(${var})) {";
        $perl .= "for (my ${i} = 0; ${i} < \@{${var}}; ${i}++) {";
        $perl .= "${var}->[${i}] = $val;";
        $perl .= "}}";
    }
    else {
        $perl .= "if (is_hash_ref(${var})) {";
        $perl .= "${var}->{${str_key}} = $val;";
        $perl .= "}";
    }

    $perl;
}

sub emit_delete_key {
    my ($self, $var, $key, $cb) = @_;

    my $str_key = $self->emit_string($key);
    my $perl    = "";
    my $vals;
    if ($cb) {
        $vals = $self->_generate_var;
        $perl = $self->emit_declare_vars($vals, '[]');
    }

    if ($key =~ /^[0-9]+$/) {
        $perl .= "if (is_hash_ref(${var}) && exists(${var}->{${str_key}})) {";
        $perl .= "push(\@{${vals}}, " if $cb;
        $perl .= "delete(${var}->{${str_key}})";
        $perl .= ")" if $cb;
        $perl .= ";";
        $perl .= "} elsif (is_array_ref(${var}) && \@{${var}} > ${key}) {";
        $perl .= "push(\@{${vals}}, " if $cb;
        $perl .= "splice(\@{${var}}, ${key}, 1)";
        $perl .= ")" if $cb;
    }
    elsif ($key eq '$first' || $key eq '$last' || $key eq '*') {
        $perl .= "if (is_array_ref(${var}) && \@{${var}}) {";
        $perl .= "push(\@{${vals}}, "                    if $cb;
        $perl .= "splice(\@{${var}}, 0, 1)"              if $key eq '$first';
        $perl .= "splice(\@{${var}}, \@{${var}} - 1, 1)" if $key eq '$last';
        $perl .= "splice(\@{${var}}, 0, \@{${var}})"     if $key eq '*';
        $perl .= ")"                                     if $cb;
    }
    else {
        $perl .= "if (is_hash_ref(${var}) && exists(${var}->{${str_key}})) {";
        $perl .= "push(\@{${vals}}, " if $cb;
        $perl .= "delete(${var}->{${str_key}})";
        $perl .= ")" if $cb;
    }
    $perl .= ";";
    $perl .= "}";
    if ($cb) {
        $perl .= $cb->($vals);
    }

    $perl;
}

sub emit_retain_key {
    my ($self, $var, $key) = @_;

    my $perl = "";

    if ($key =~ /^[0-9]+$/) {
        $perl .= "if (is_hash_ref(${var})) {";
        $perl .= $self->emit_foreach_key(
            $var,
            sub {
                my $v = shift;
                "delete(${var}->{${v}}) if ${v} ne ${key};";
            }
        );
        $perl .= "} elsif (is_array_ref(${var})) {";
        $perl .= "if (\@{${var}} > ${key}) {";
        $perl .= "splice(\@{${var}}, 0, ${key});" if $key > 0;
        $perl .= "splice(\@{${var}}, 1, \@{${var}} - 1);";
        $perl .= "} else {";
        $perl .= "splice(\@{${var}}, 0, \@{${var}});";
        $perl .= "}";
        $perl .= "}";
    }
    elsif ($key eq '$first') {
        $perl .= "if (is_array_ref(${var}) && \@{${var}} > 1) {";
        $perl .= "splice(\@{${var}}, 1, \@{${var}} - 1);";
        $perl .= "}";
    }
    elsif ($key eq '$last') {
        $perl .= "if (is_array_ref(${var}) && \@{${var}} > 1) {";
        $perl .= "splice(\@{${var}}, 0, \@{${var}} - 1);";
        $perl .= "}";
    }
    elsif ($key eq '*') {

        # retain everything
    }
    else {
        $key = $self->emit_string($key);
        $perl .= "if (is_hash_ref(${var})) {";
        $perl .= $self->emit_foreach_key(
            $var,
            sub {
                my $v = shift;
                "if ($v ne ${key}) {" . "delete(${var}->{${v}});" . "}";
            }
        );
        $perl .= "}";
    }

    $perl;
}

sub emit_clone {
    my ($self, $var) = @_;
    "$var = clone($var);";
}

# Split a path on '.' or '/', but not on '\.' or '\/'.
sub split_path {
    my ($self, $path) = @_;
    Catmandu::Util::split_path($path);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix - a Catmandu class used for data transformations

=head1 SYNOPSIS

    # From the command line

    $ catmandu convert JSON --fix 'add(foo,bar)' < data.json
    $ catmandu convert YAML --fix 'upcase(job) remove(test)' < data.yml
    $ catmandu convert CSV  --fix 'sort(tags)' < data.csv
    $ catmandu run /tmp/myfixes.txt
    $ catmandu convert OAI --url http://biblio.ugent.be/oai --fix /tmp/myfixes.txt

    # With preprocessing
    $ catmandu convert JSON --var field=foo --fix 'add({{field}},bar)' < data.json

    # From Perl

    use Catmandu;

    my $fixer = Catmandu->fixer('upcase(job)','removed(test)');
    my $fixer = Catmandu->fixer('/tmp/myfixes.txt');

    # Convert data
    my $arr      = $fixer->fix([ ... ]);
    my $hash     = $fixer->fix({ ... });
    my $importer = Catmandu->importer('YAML', file => 'data.yml');
    my $fixed_importer = $fixer->fix($importer);

    # With preprocessing
    my $fixer = Catmandu::Fix->new(
        variables => {x => 'foo', y => 'bar'},
        fixes => ['add({{x}},{{y}})'],
    );

    # Inline fixes
    use Catmandu::Fix::upcase as => 'my_upcase';
    use Catmandu::Fix::remove as => 'my_remove';

    my $hash = { 'job' => 'librarian' , deep => { nested => '1'} };

    my_upcase($hash,'job');
    my_remove($hash,'deep.nested');

=head1 DESCRIPTION

A Catmandu::Fix is a Perl package that can transform data. These packages are used
for easy data manipulation by non programmers. The main intention is to use fixes
on the command line or in Fix scripts. A small DSL language is available to execute
many Fix command on a stream of data.

When a C<fix> argument is given to a L<Catmandu::Importer>, L<Catmandu::Exporter> or
L<Catmandu::Store> then the transformations are executed on every item in the stream.

=head1 FIX LANGUAGE

A Fix script is a collection of one or more Fix commands. The fixes are executed
on every record in the dataset. If this command is executed on the command line:

    $ catmandu convert JSON --fix 'upcase(title); add(deep.nested.field,1)' < data.json

then all the title fields will be upcased and a new deeply nested field will be added:

    { "title":"foo" }
    { "title":"bar" }

becomes:

    { "title":"FOO" , "deep":{"nested":{"field":1}} }
    { "title":"BAR" , "deep":{"nested":{"field":1}} }

Using the command line, Fix commands need a semicolon (;) as separator. All these commands can
also be written into a Fix script where semicolons are not required:

    $ catmandu convert JSON --fix script.fix < data.json

where C<script.fix> contains:

    upcase(title)
    add(deep.nested.field,1)

Conditionals can be used to provide the logic when to execute fixes:

    if exists(error)
        set(valid, 0)
    end

    if exists(error)
        set(is_valid, 0)
    elsif exists(warning)
        set(is_valid, 1)
        log(...)
    else
        set(is_valid, 1)
    end

    unless all_match(title, "PERL")
        add(is_perl, "noooo")
    end

    exists(error) and set(is_valid, 0)
    exists(error) && set(is_valid, 0)

    exists(title) or log('title missing')
    exists(title) || log('title missing')

Binds are used to manipulate the context in which Fixes are executed. E.g.
execute a fix on every item in a list:

     # 'demo' is an array of hashes
     bind list(path:demo)
        add_field(foo,bar)
     end
     # do is an alias for bind
     do list(path:demo)
        add_field(foo,bar)
     end

To delete records from a stream of data the C<reject> Fix can be used:

    reject()           #  Reject all in the stream

    if exists(foo)
        reject()       # Reject records that contain a 'foo' field
    end

    reject exists(foo) # Reject records that contain a 'foo' field

The opposite of C<reject> is C<select>:

    select()           # Keep all records in the stream

    select exists(foo) # Keep only the records that contain a 'foo' field

Comments in Fix scripts are all lines (or parts of a line) that start with a hash (#):

    # This is ignored
    add(test,123)      # This is also a comment

You can load fixes from another namespace with the C<use> statement:

    # this will look for fixes in the Foo::Bar namespace and make them
    # available prefixed by fb
    use(foo.bar, as: fb)
    fb.baz()

    # this will look for Foo::Bar::Condition::is_baz
    if fb.is_baz()
       ...
       fix()
       ...
    end

=head1 FIX COMMANDS, ARGUMENTS AND OPTIONS

Fix commands manipulate data or in some cases execute side effects. Fix
commands have zero or more arguments and zero or more options. Fix command
arguments are separated by commas ",". Fix options are name/value pairs
separated by a colon ":".

    # A command with zero arguments
    my_command()

    # A command with multiple arguments
    my_other_command(foo,bar,test)

    # A command with optional arguments
    my_special_command(foo,bar,color:blue,size:12)

All command arguments are treated as strings. These strings can be FIX PATHs
pointing to values or string literals. When command line arguments don't contain
special characters comma "," , equal "=" , great than ">" or colon ":", then
they can be written as-is. Otherwise, the arguments need to be quoted with single
or double quotes:

    # Both commands below have the same effect
    my_other_command(foo,bar,test)
    my_other_command("foo","bar","test")

    # Illegal syntax
    my_special_command(foo,http://test.org,color:blue,size:12) # <- syntax error

    # Correct syntax
    my_special_command(foo,"http://test.org",color:blue,size:12)
    
    # Or, alternative
    my_special_command("foo","http://test.org",color:"blue",size:12)

=head1 FIX PATHS

Most of the Fix commands use paths to point to values
in a data record. E.g. 'foo.2.bar' is a key 'bar' which is the 3-rd value of the
key 'foo'.

A special case is when you want to point to all items in an array. In this case
the wildcard '*' can be used. E.g. 'foo.*' points to all the items in the 'foo'
array.

For array values there are special wildcards available:

 * $append   - Add a new item at the end of an array
 * $prepend  - Add a new item at the start of an array
 * $first    - Syntactic sugar for index '0' (the head of the array)
 * $last     - Syntactic sugar for index '-1' (the tail of the array)

E.g.

 # Create { mods => { titleInfo => [ { 'title' => 'a title' }] } };
 add('mods.titleInfo.$append.title', 'a title');

 # Create { mods => { titleInfo => [ { 'title' => 'a title' } , { 'title' => 'another title' }] } };
 add('mods.titleInfo.$append.title', 'another title');

 # Create { mods => { titleInfo => [ { 'title' => 'foo' } , { 'title' => 'another title' }] } };
 add('mods.titleInfo.$first.title', 'foo');

 # Create { mods => { titleInfo => [ { 'title' => 'foo' } , { 'title' => 'bar' }] } };
 add('mods.titleInfo.$last.title', 'bar');

Some Fix commands can implement an alternatice path syntax to point to values.
See for example L<Catmandu::MARC>, L<Catmandu:PICA>:

 # Copy the MARC 245a field to the my.title field
 marc_map(245a,my.title)

=head1 OPTIONS

=head2 fixes

An array of fixes. L<Catmandu::Fix> which will execute every fix in consecutive
order. A fix can be the name of a Catmandu::Fix::* routine, or the path to a
plain text file containing all the fixes to be executed. Required.

=head2 preprocess

If set to C<1>, fix files or inline fixes will first be preprocessed as a
moustache template. See C<variables> below for an example. Default is C<0>, no
preprocessing.

=head2 variables

An optional hashref of variables that are used to preprocess the fix files or
inline fixes as a moustache template. Setting the C<variables> option also sets
C<preprocess> to 1.

    my $fixer = Catmandu::Fix->new(
        variables => {x => 'foo', y => 'bar'},
        fixes => ['add({{x}},{{y}})'],
    );
    my $data = {};
    $fixer->fix($data);
    # $data is now {foo => 'bar'}

=head1 METHODS

=head2 fix(HASH)

Execute all the fixes on a HASH. Returns the fixed HASH.

=head2 fix(ARRAY)

Execute all the fixes on every element in the ARRAY. Returns an ARRAY of fixes.

=head2 fix(Catmandu::Iterator)

Execute all the fixes on every item in an L<Catmandu::Iterator>. Returns a
(lazy) iterator on all the fixes.

=head2 fix(sub {})

Executes all the fixes on a generator function. Returns a new generator with fixed data.

=head2 log

Return the current logger. See L<Catmandu> for activating the logger in your main code.

=head1 CODING

One can extend the Fix language by creating own custom-made fixes. Three methods are
available to create an new fix function:

  * Simplest: create a class that implements a C<fix> method.
  * For most use cases: create a class that consumes the C<Catmandu::Fix::Builder> role and use C<Catmandu::Path> to build your fixer.
  * Hardest: create a class that emits Perl code that will be evaled by the Fix module.

Both methods will be explained shortly.

=head2 Quick and easy

A Fix function is a Perl class in the C<Catmandu::Fix> namespace that implements a C<fix> method.
The C<fix> methods accepts a Perl hash as input and returns a (fixed) Perl hash as output. As
an example, the code belows implements the C<meow> Fix which inserts a 'meow' field with value 'purrrrr'.

    package Catmandu::Fix::meow;

    use Moo;

    sub fix {
        my ($self,$data) = @_;
        $data->{meow} = 'purrrrr';
        $data;
    }

    1;

Given this Perl class, the following fix statement can be used in your application:

    # Will add 'meow' = 'purrrrr' to the data
    meow()

Use the quick and easy method when your fixes are not dependent on reading or writing data
from/to a JSON path. Your Perl classes need to implement their own logic to read or write data
into the given Perl hash.

Fix arguments are passed as arguments to the C<new> function of the Perl class. As in

    # In the fix file...
    meow('test123', count: 4)

    # ...will be translated into this pseudo code
    my $fix = Catmandu::Fix::meow->new('test123', count: 4);

Using L<Moo> these arguments can be catched with L<Catmandu::Fix::Has> package:

    package Catmandu::Fix::meow;

    use Catmandu::Sane;
    use Moo;
    use Catmandu::Fix::Has;

    has msg   => (fix_arg => 1); # required parameter 1
    has count => (fix_opt => 1, default => sub { 4 }); # optional parameter 'count' with default value 4

    sub fix {
        my ($self,$data) = @_;
        $data->{meow} = $self->msg x $self->count;
        $data;
    }

    1;

Using this code the fix statement can be used like:

    # Will add 'meow' = 'purrpurrpurrpurr'
    meow('purr', count: 4)

=head1 SEE ALSO

L<Catmandu::Fixable>,
L<Catmandu::Importer>,
L<Catmandu::Exporter>,
L<Catmandu::Store>,
L<Catmandu::Bag>

=cut
