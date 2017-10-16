package Catmandu::Path::default;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Catmandu::Util
    qw(is_hash_ref is_array_ref is_value is_string is_code_ref trim);
use Moo;
use namespace::clean;

with 'Catmandu::Path', 'Catmandu::Emit';

use overload '""' => sub {$_[0]->path};

sub split_path {
    my ($self) = @_;
    my $path = $self->path;
    if (is_value($path)) {
        [map {s/\\(?=[\.\/])//g; $_} split /(?<!\\)[\.\/]/, trim($path)];
    }
    elsif (is_array_ref($path)) {
        $path;
    }
    else {
        # TODO
    }
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
    ) . "return $vals_var;";

    $self->_eval_sub($body, args => [$data_var]);
}

sub setter {
    my ($self, %opts) = @_;
    my $path     = $self->split_path;
    my $key      = pop @$path;
    my $data_var = $self->_generate_var;
    my $val_var  = $self->_generate_var;

    my $body = $self->_emit_get(
        $data_var,
        $path,
        sub {
            my $var = $_[0];
            $self->_emit_set_key($var, $key, $val_var);
        },
    ) . "return;";

    if (my $val = $opts{value}) {
        $self->_eval_sub(
            $body,
            args     => [$data_var],
            captures => {$val_var => $val}
        );
    }
    else {
        $self->_eval_sub($body, args => [$data_var, $val_var]);
    }
}

sub updater {
    my ($self, %opts) = @_;
    my $path     = $self->split_path;
    my $data_var = $self->_generate_var;
    my $captures = {};
    my $args     = [$data_var];
    my $cb;

    if (my $predicates = $opts{if}) {
        $cb = sub {
            my ($var, %opts) = @_;
            my $perl = "";
            for (my $i = 0; $i < @$predicates; $i += 2) {
                my $pred    = $predicates->[$i];
                my $val     = $predicates->[$i + 1];
                my $val_var = $self->_generate_var;
                $captures->{$val_var} = $val;
                $pred = [$pred] if is_string($pred);
                if ($i) {
                    $perl .= 'els';
                }
                $perl
                    .= 'if ('
                    . join(' || ', map {"is_${_}(${var})"} @$pred) . ') {'
                    . $self->_emit_assign($var, "${val_var}->(${var})", %opts) . '}';
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
            $self->_emit_assign($var, "${val_var}->(${var})", %opts);
        };
    }

    my $body = $self->_emit_get($data_var, $path, $cb) . 'return;';

    $self->_eval_sub($body, args => $args, captures => $captures);
}

sub _emit_assign {
    my ($self, $var, $val, %opts) = @_;
    my $l_var  = $var;
    my $up_var = $opts{up_var};
    if (my $key = $opts{key}) {
        $l_var = "${up_var}->{${key}}";
    }
    elsif (my $index = $opts{index}) {
        $l_var = "${up_var}->[${index}]";
    }
    "${l_var} = ${val};";
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
            "${var} = ${val_var}->(${var});";
        };
    }
    elsif (exists $opts{value}) {
        my $val = $self->_emit_value($opts{value});
        $cb = sub {
            my $var = $_[0];
            "${var} = ${val};";
        };
    }
    else {
        push @$args, $val_var;
        $cb = sub {
            my $var = $_[0];
            "if (is_code_ref(${val_var})) {"
                . "${var} = ${val_var}->(${var});"
                . '} else {'
                . "${var} = ${val_var};" . '}';
        };
    }

    my $body = $self->_emit_create_path($data_var, $path, $cb) . "return;";

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
    );

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
    $var = $self->_generate_var;

    if ($key =~ /^[0-9]+$/) {
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

#sub _emit_get_key {
#my ($self, $var, $key, $cb) = @_;

#return $cb->($var) unless defined $key;

#my $str_key = $self->_emit_string($key);
#my $perl    = "";

#if ($key =~ /^[0-9]+$/) {
#$perl .= "if (is_hash_ref(${var}) && exists(${var}->{${str_key}})) {";
#$perl .= $cb->("${var}->{${str_key}}");
#$perl .= "} elsif (is_array_ref(${var}) && \@{${var}} > ${key}) {";
#$perl .= $cb->("${var}->[${key}]");
#$perl .= "}";
#}
#elsif ($key eq '$first') {
#$perl .= "if (is_array_ref(${var}) && \@{${var}}) {";
#$perl .= $cb->("${var}->[0]");
#$perl .= "}";
#}
#elsif ($key eq '$last') {
#$perl .= "if (is_array_ref(${var}) && \@{${var}}) {";
#$perl .= $cb->("${var}->[\@{${var}} - 1]");
#$perl .= "}";
#}
#elsif ($key eq '*') {
#my $i = $self->_generate_var;
#$perl .= "if (is_array_ref(${var})) {";
#$perl .= $self->_emit_foreach($var, $cb);
#$perl .= "}";
#}
#else {
#$perl .= "if (is_hash_ref(${var}) && exists(${var}->{${str_key}})) {";
#$perl .= $cb->("${var}->{${str_key}}");
#$perl .= "}";
#}

#$perl;
#}

sub _emit_set_key {
    my ($self, $var, $key, $val) = @_;

    return "${var} = $val;" unless defined $key;

    my $perl    = "";
    my $str_key = $self->_emit_string($key);

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

sub _emit_create_path {
    my ($self, $var, $path, $cb) = @_;

    @$path || return $cb->($var);

    my $key     = shift @$path;
    my $str_key = $self->_emit_string($key);
    my $perl    = "";

    if ($key =~ /^[0-9]+$/) {
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
    my ($self, $var, $key, $cb) = @_;

    my $str_key = $self->_emit_string($key);
    my $perl    = "";
    my $vals;
    if ($cb) {
        $vals = $self->_generate_var;
        $perl = $self->_emit_declare_vars($vals, '[]');
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
        $perl .= "push(\@{${vals}}, " if $cb;
        $perl .= "splice(\@{${var}}, 0, 1)" if $key eq '$first';
        $perl .= "splice(\@{${var}}, \@{${var}} - 1, 1)" if $key eq '$last';
        $perl .= "splice(\@{${var}}, 0, \@{${var}})" if $key eq '*';
        $perl .= ")" if $cb;
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

1;
