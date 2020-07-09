package Catmandu::Emit;

# eval context ->
use Catmandu::Sane;

our $VERSION = '1.2013';

use Catmandu::Util qw(:is :string require_package);
use Clone qw(clone);
require Catmandu;    # avoid circular dependencies

sub _eval_emit {
    eval $_[0];
}

# <- eval context

use B ();
use Moo::Role;

# global state ->
sub _reject {
    state $reject = {};
}

sub _generate_label {
    state $num_labels = 0;
    my $label = "__CATMANDU__FIX__${num_labels}";
    $num_labels++;
    $label;
}

sub _reject_label {
    state $reject_label = _generate_label;
}

sub _generate_var {
    state $num_vars = 0;
    my $var = "\$__catmandu__${num_vars}";
    $num_vars++;
    $var;
}

# <- global state

sub _eval_sub {
    my ($self, @args) = @_;
    local $@;
    _eval_emit($self->_emit_sub(@args)) or Catmandu::Error->throw($@);
}

sub _emit_sub {
    my ($self, $body, %opts) = @_;
    my $captures = $opts{captures} ||= {};
    my $perl     = "sub {";
    if (my $args = $opts{args}) {
        $perl .= 'my (' . join(', ', @$args) . ') = @_;';
    }
    $perl .= $body;
    $perl .= "};";
    my @captured_vars = map {
        $self->_emit_declare_vars($_,
            '$_[1]->{' . $self->_emit_string($_) . '}');
    } keys %$captures;
    $perl = join('', @captured_vars, $perl);

    return $perl, $captures;
}

sub _emit_declare_vars {
    my ($self, $var, $val) = @_;
    $var = "(" . join(", ", @$var) . ")" if is_array_ref($var);
    $val = "(" . join(", ", @$val) . ")" if is_array_ref($val);
    if (defined $val) {
        return "my ${var} = ${val};";
    }
    "my ${var};";
}

sub _emit_branch {
    my ($self, $test, $pass, $fail) = @_;
    "if (${test}) {${pass}} else {${fail}}";
}

sub _emit_call {
    my ($self, $sub_var, @args) = @_;
    "${sub_var}->(" . join(', ', @args) . ")";
}

sub _emit_iterate_array {
    my ($self, $var, $cb) = @_;
    my $perl = "";
    my $i    = $self->_generate_var;

    # loop backwards so that deletions are safe
    $perl .= "for (my ${i} = \@{${var}} - 1; ${i} >= 0; ${i}--) {";
    $perl .= $cb->("${var}->[${i}]", up_var => $var, index => $i);
    $perl .= "}";
    $perl;
}

sub _emit_iterate_hash {
    my ($self, $var, $cb) = @_;
    my $perl = "";
    my $k    = $self->generate_var;

    $perl .= "for my ${k} (keys(\%{${var}})) {";
    $perl .= $cb->("${var}->{${k}}", up_var => $var, key => $k);
    $perl .= "}";
    $perl;
}

sub _emit_assign_cb {
    my ($self, $var, $cb_var, %opts) = @_;
    my $val_var    = $self->_generate_var;
    my $cancel_var = $self->_generate_var;
    my $delete_var = $self->_generate_var;
    my $perl       = "";
    $perl
        .= "my (${val_var}, ${cancel_var}, ${delete_var}) = ${cb_var}->(${var});";
    $perl .= "if (${delete_var}) {";
    $perl .= $self->_emit_delete(%opts);
    $perl .= "} elsif (!${cancel_var}) {";
    $perl .= $self->_emit_assign($var, $val_var, %opts);
    $perl .= "}";
    $perl;
}

sub _emit_assign {
    my ($self, $var, $val, %opts) = @_;
    my $l_var = $var;
    if (my $up_var = $opts{up_var}) {
        if (defined(my $key = $opts{key})) {
            $l_var = "${up_var}->{${key}}";
        }
        elsif (defined(my $index = $opts{index})) {
            $l_var = "${up_var}->[${index}]";
        }
        else {
            Catmandu::BadArg->throw('up_var without key or index');
        }
    }
    "${l_var} = ${val};";
}

sub _emit_delete {
    my ($self, %opts) = @_;
    my $up_var = $opts{up_var};
    if (!defined($up_var)) {

        # TODO deleting the root object is equivalent to reject
        $self->_emit_reject;
    }
    elsif (defined(my $key = $opts{key})) {
        "delete ${up_var}->{${key}}";
    }
    elsif (defined(my $idx = $opts{index})) {
        "splice(\@{${up_var}}, ${idx}, 1)";
    }
    else {
        Catmandu::BadArg->throw('up_var without key or index');
    }
}

sub _emit_value {
    my ($self, $val) = @_;

    ## undef
    return 'undef' unless defined $val;

    ## numbers
    # we don't quote ints and floats unless there are leading
    # (and for floats trailing) zero's
    if (is_integer($val)) {
        return $val;
    }
    if (is_float($val) && $val !~ /0$/) {
        return $val;
    }

    ## strings
    $self->_emit_string($val);
}

sub _emit_string {
    my ($self, $str) = @_;
    B::perlstring($str);
}

sub _emit_reject {
    my ($self) = @_;
    'goto ' . $self->_reject_label . ';';
}

1;

__END__

=pod

=head1 NAME

Catmandu::Emit - Role with helper methods for code emitting

=cut
