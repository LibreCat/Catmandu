package Catmandu::Path::simple;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Catmandu::Util
    qw(is_hash_ref is_array_ref is_value is_natural is_code_ref trim);
use Moo;
use namespace::clean;

with 'Catmandu::Path', 'Catmandu::Emit';

use overload '""' => sub {$_[0]->path};

sub split_path {
    my ($self) = @_;
    my $path = $self->path;
    if (is_value($path)) {
        $path = trim($path);
        $path =~ s/^\$[\.\/]//;
        $path = [map {s/\\(?=[\.\/])//g; $_} split /(?<!\\)[\.\/]/, $path];
        return $path;
    }
    if (is_array_ref($path)) {
        return $path;
    }
    Catmandu::Error->throw("path should be a string or arrayref of strings");
}

sub getter {
    my ($self)   = @_;
    my $path     = $self->split_path;
    my $data_var = $self->_generate_var;
    my $vals_var = $self->_generate_var;

    my $body = $self->_emit_declare_vars($vals_var, '[]') . $self->_emit_get(
        $data_var,
        $path,
        sub {
            my ($var, %opts) = @_;

            # looping goes backwards to keep deletions safe
            "unshift(\@{${vals_var}}, ${var});";
        },
    ) . "return ${vals_var};";

    $self->_eval_sub($body, args => [$data_var]);
}

sub setter {
    my $self     = shift;
    my %opts     = @_ == 1 ? (value => $_[0]) : @_;
    my $path     = $self->split_path;
    my $key      = pop @$path;
    my $data_var = $self->_generate_var;
    my $val_var  = $self->_generate_var;
    my $captures = {};
    my $args     = [$data_var];

    my $body = $self->_emit_get(
        $data_var,
        $path,
        sub {
            my $var = $_[0];
            my $val;
            if (is_code_ref($opts{value})) {
                $captures->{$val_var} = $opts{value};
                $val = "${val_var}->(${var}, ${data_var})";
            }
            elsif (exists $opts{value}) {
                $captures->{$val_var} = $opts{value};
                $val = $val_var;
            }
            else {
                push @$args, $val_var;
                $val
                    = "is_code_ref(${val_var}) ? ${val_var}->(${var}, ${data_var}) : ${val_var}";
            }

            $self->_emit_set_key($var, $key, $val);
        },
    ) . "return ${data_var};";

    $self->_eval_sub($body, args => $args, captures => $captures);
}

sub updater {
    my ($self, %opts) = @_;
    my $path     = $self->split_path;
    my $data_var = $self->_generate_var;
    my $captures = {};
    my $args     = [$data_var];
    my $cb;

    if (my $tests = $opts{if}) {
        $cb = sub {
            my ($var, %opts) = @_;
            my $perl = "";
            for (my $i = 0; $i < @$tests; $i += 2) {
                my $test     = $tests->[$i];
                my $val      = $tests->[$i + 1];
                my $test_var = $self->_generate_var;
                my $val_var  = $self->_generate_var;
                $captures->{$test_var} = $test;
                $captures->{$val_var}  = $val;
                if ($i) {
                    $perl .= 'els';
                }
                $perl
                    .= "if (List::Util::any {\$_->(${var})} \@{${test_var}}) {"
                    . $self->_emit_assign_cb($var, $val_var, %opts) . '}';
            }
            $perl;
        };
    }
    else {
        my $val_var = $self->_generate_var;
        if (my $val = $opts{value}) {
            $captures->{$val_var} = $val;
        }
        else {
            push @$args, $val_var;
        }
        $cb = sub {
            my ($var, %opts) = @_;
            $self->_emit_assign_cb($var, $val_var, %opts);
        };
    }

    my $body
        = $self->_emit_get($data_var, $path, $cb) . "return ${data_var};";

    $self->_eval_sub($body, args => $args, captures => $captures);
}

sub creator {
    my ($self, %opts) = @_;
    my $path     = $self->split_path;
    my $data_var = $self->_generate_var;
    my $val_var  = $self->_generate_var;
    my $captures = {};
    my $args     = [$data_var];
    my $cb;

    if (is_code_ref($opts{value})) {
        $captures->{$val_var} = $opts{value};
        $cb = sub {
            my $var = $_[0];
            "${var} = ${val_var}->(${var}, ${data_var});";
        };
    }
    elsif (exists $opts{value}) {
        $captures->{$val_var} = $opts{value};
        $cb = sub {
            my $var = $_[0];
            "${var} = ${val_var};";
        };
    }
    else {
        push @$args, $val_var;
        $cb = sub {
            my $var = $_[0];
            "if (is_code_ref(${val_var})) {"
                . "${var} = ${val_var}->(${var}, ${data_var});"
                . '} else {'
                . "${var} = ${val_var};" . '}';
        };
    }

    my $body = $self->_emit_create_path($data_var, $path, $cb);

    $body .= "return ${data_var};";

    $self->_eval_sub($body, args => $args, captures => $captures);
}

sub deleter {
    my ($self)   = @_;
    my $path     = $self->split_path;
    my $key      = pop @$path;
    my $data_var = $self->_generate_var;

    my $body = $self->_emit_get(
        $data_var,
        $path,
        sub {
            my $var = $_[0];
            $self->_emit_delete_key($var, $key);
        }
    ) . "return ${data_var};";

    $self->_eval_sub($body, args => [$data_var]);
}

sub _emit_get {
    my ($self, $var, $path, $cb, %opts) = @_;

    @$path || return $cb->($var, %opts);

    $path = [@$path];

    my $key     = shift @$path;
    my $str_key = $self->_emit_string($key);
    my $perl    = "";

    %opts = (up_var => my $up_var = $var);
    $var  = $self->_generate_var;

    if (is_natural($key)) {
        $perl
            .= "if (is_hash_ref(${up_var}) && exists(${up_var}->{${str_key}})) {";
        $perl .= "my ${var} = ${up_var}->{${str_key}};";
        $perl .= $self->_emit_get($var, $path, $cb, %opts, key => $str_key);
        $perl
            .= "} elsif (is_array_ref(${up_var}) && \@{${up_var}} > ${key}) {";
        $perl .= "my ${var} = ${up_var}->[${key}];";
        $perl .= $self->_emit_get($var, $path, $cb, %opts, index => $key);
        $perl .= "}";
    }
    elsif ($key eq '*') {
        $perl .= "if (is_array_ref(${up_var})) {";
        $perl .= $self->_emit_iterate_array(
            $up_var,
            sub {
                my ($v, %opts) = @_;
                "my ${var} = ${v};"
                    . $self->_emit_get($var, $path, $cb, %opts);
            }
        );
        $perl .= "}";
    }
    else {
        if ($key eq '$first') {
            $opts{index} = 0;
            $perl .= "if (is_array_ref(${up_var}) && \@{${up_var}}) {";
            $perl .= "my ${var} = ${up_var}->[0];";
        }
        elsif ($key eq '$last') {
            $opts{index} = my $i = $self->_generate_var;
            $perl .= "if (is_array_ref(${up_var}) && \@{${up_var}}) {";
            $perl .= $self->_emit_declare_vars($i, "\@{${up_var}} - 1");
            $perl .= "my ${var} = ${up_var}->[${i}];";
        }
        else {
            $opts{key} = $str_key;
            $perl
                .= "if (is_hash_ref(${up_var}) && exists(${up_var}->{${str_key}})) {";
            $perl .= "my ${var} = ${up_var}->{${str_key}};";
        }
        $perl .= $self->_emit_get($var, $path, $cb, %opts);
        $perl .= "}";
    }

    $perl;
}

sub _emit_set_key {
    my ($self, $var, $key, $val) = @_;

    return "${var} = $val;" unless defined $key;

    my $perl    = "";
    my $str_key = $self->_emit_string($key);

    if (is_natural($key)) {
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

sub _emit_create_path {
    my ($self, $var, $path, $cb) = @_;

    @$path || return $cb->($var);

    my $key     = shift @$path;
    my $str_key = $self->_emit_string($key);
    my $perl    = "";

    if (is_natural($key)) {
        my $v1 = $self->_generate_var;
        my $v2 = $self->_generate_var;
        $perl .= "if (is_hash_ref(${var})) {";
        $perl .= "my ${v1} = ${var};";
        $perl
            .= $self->_emit_create_path("${v1}->{${str_key}}", [@$path], $cb);
        $perl .= "} elsif (is_maybe_array_ref(${var})) {";
        $perl .= "my ${v2} = ${var} //= [];";
        $perl .= $self->_emit_create_path("${v2}->[${key}]", [@$path], $cb);
        $perl .= "}";
    }
    elsif ($key eq '*') {
        my $v1 = $self->_generate_var;
        my $v2 = $self->_generate_var;
        $perl .= "if (is_array_ref(${var})) {";
        $perl .= "my ${v1} = ${var};";

        # loop backwards so that deletions are safe
        $perl .= "for (my ${v2} = \@{${v1}} - 1; $v2 >= 0; ${v2}--) {";
        $perl .= $self->_emit_create_path("${v1}->[${v2}]", $path, $cb);
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
                $perl .= $self->_emit_create_path("${v}->[0]", $path, $cb);
            }
            elsif ($key eq '$last') {
                $perl .= "if (\@${v}) {";
                $perl .= $self->_emit_create_path("${v}->[\@${v} - 1]",
                    [@$path], $cb);
                $perl .= "} else {";
                $perl .= $self->_emit_create_path("${v}->[0]", [@$path], $cb);
                $perl .= "}";
            }
            elsif ($key eq '$prepend') {
                $perl .= "if (\@${v}) {";
                $perl .= "unshift(\@${v}, undef);";
                $perl .= "}";
                $perl .= $self->_emit_create_path("${v}->[0]", $path, $cb);
            }
            elsif ($key eq '$append') {
                my $index_var = $self->_generate_var;
                $perl
                    .= $self->_emit_declare_vars($index_var, "scalar(\@${v})")
                    . $self->_emit_create_path("${v}->[${index_var}]", $path,
                    $cb);
            }
            $perl .= "}";
        }
        else {
            $perl .= "if (is_maybe_hash_ref(${var})) {";
            $perl .= "my ${v} = ${var} //= {};";
            $perl
                .= $self->_emit_create_path("${v}->{${str_key}}", $path, $cb);
            $perl .= "}";
        }
    }

    $perl;
}

sub _emit_delete_key {
    my ($self, $var, $key) = @_;

    my $str_key = $self->_emit_string($key);
    my $perl    = "";

    if (is_natural($key)) {
        $perl .= "if (is_hash_ref(${var}) && exists(${var}->{${str_key}})) {";
        $perl .= "delete(${var}->{${str_key}});";
        $perl .= "} elsif (is_array_ref(${var}) && \@{${var}} > ${key}) {";
        $perl .= "splice(\@{${var}}, ${key}, 1)";
    }
    elsif ($key eq '$first' || $key eq '$last' || $key eq '*') {
        $perl .= "if (is_array_ref(${var}) && \@{${var}}) {";
        $perl .= "splice(\@{${var}}, 0, 1)"              if $key eq '$first';
        $perl .= "splice(\@{${var}}, \@{${var}} - 1, 1)" if $key eq '$last';
        $perl .= "splice(\@{${var}}, 0, \@{${var}})"     if $key eq '*';
    }
    else {
        $perl .= "if (is_hash_ref(${var})) {";
        $perl .= "delete(${var}->{${str_key}})";
    }
    $perl .= ";";
    $perl .= "}";

    $perl;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Path::simple - The default Catmandu path syntax

=head1 SYNOPSIS

    my $data = {foo => {bar => ['first_bar', 'second_bar']}};

    my $path = Catmandu::Path::simple->new("foo.bar.0");

    my $getter = $path->getter;
    my $first_bar = $getter->($data);

    my $updater = $path->updater(sub { my $str = $_[0]; uc $str });
    $updater->($data);
    # => {foo => {bar => ['FIRST_BAR', 'second_bar']}}

    # safer version with a type check
    my $updater = $path->updater(if_string => sub { my $str = $_[0]; uc $str });

=head1 CONFIGURATION

=over 4

=item path

The string version of the path. Required.

=back

=head1 METHODS

=head2 getter

Returns a coderef that can get the values for the path.
The coderef takes the data as argument and returns the matching values as an
arrayref.

    my $path = Catmandu::Path::Simple->new(path => '$.foo');
    my $data = {foo => 'foo', bar => 'bar'};
    $path->getter->($data);
    # => ['foo']

=head2 setter

Returns a coderef that can create the final part of the  path and set it's
value. In contrast to C<creator> this will only set the value if the
intermediate path exists.  The coderef takes the data as argument and also
returns the data.

    my $path = Catmandu::Path::Simple->new(path => '$.foo.$append');
    $path->creator(value => 'foo')->({});
    # => {foo => ['foo']}
    $path->creator(value => sub { my ($val, $data) = @_; $val // 'foo' })->({});
    # => {foo => ['foo']}

    # calling creator with no value creates a sub that takes the value as an
    # extra argument
    $path->creator->({}, 'foo');
    $path->creator->({}, sub { my ($val, $data) = @_; $val // 'foo' });
    # => {foo => ['foo']}

=head2 setter(\&callback|$value)

This is a shortcut for C<setter(value => \&callback|$value)>.

=head2 updater(value => \&callback)

Returns a coderef that can update the value of an existing path.

=head2 updater(if_* => [\&callback])

TODO

=head2 updater(if => [\&callback])

TODO

=head2 updater(if_* => \&callback)

TODO

=head2 updater(if => \&callback)

TODO

=head2 updater(\&callback)

This is a shortcut for C<updater(value => \&callback|$value)>.

=head2 creator(value => \&callback|$value)

Returns a coderef that can create the path and set it's value. In contrast to
C<setter> this also creates the intermediate path if necessary.
The coderef takes the data as argument and also returns the data.

    my $path = Catmandu::Path::Simple->new(path => '$.foo.$append');
    $path->creator(value => 'foo')->({});
    # => {foo => ['foo']}
    $path->creator(value => sub { my ($val, $data) = @_; $val // 'foo' })->({});
    # => {foo => ['foo']}

    # calling creator with no value creates a sub that takes the value as an
    # extra argument
    $path->creator->({}, 'foo');
    $path->creator->({}, sub { my ($val, $data) = @_; $val // 'foo' });
    # => {foo => ['foo']}

=head2 creator(\&callback|$value)

This is a shortcut for C<creator(value => \&callback|$value)>.

=head2 deleter

Returns a coderef that can delete the path.
The coderef takes the data as argument and also returns the data.

    my $path = Catmandu::Path::Simple->new(path => '$.foo');
    $path->deleter->({foo => 'foo', bar => 'bar'});
    # => {bar => 'bar'}

=head1 SEE ALSO

L<Catmandu::Path>.

=cut
