package Catmandu::Emit;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Catmandu;
use Catmandu::Util qw(:is :string);

sub _eval_emit {
    use warnings FATAL => 'all';
    eval $_[0];
}

use B ();
use Moo::Role;

has _num_vars => (is => 'rw', lazy => 1, default => sub {0});

sub _generate_var {
    my ($self) = @_;
    my $n = $self->_num_vars;
    $self->_num_vars($n + 1);
    "\$__$n";
}

sub _eval_sub {
    my ($self, @args) = @_;
    _eval_emit($self->_emit_sub(@args));
}

sub _emit_sub {
    my ($self, $body, %opts) = @_;
    my $captures = $opts{captures} ||= {};
    my $perl = "sub {";
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
    $var = "(" . join(", ", @$var) . ")" if ref $var;
    $val = "(" . join(", ", @$val) . ")" if ref $val;
    if (defined $val) {
        return "my ${var} = ${val};";
    }
    "my ${var};";
}

sub _emit_foreach {
    my ($self, $var, $cb) = @_;
    my $perl = "";
    my $v    = $self->_generate_var;
    $perl .= "foreach my $v (\@{${var}}) {";
    $perl .= $cb->($v);
    $perl .= "}";
    $perl;
}

sub _emit_value {
    my ($self, $val) = @_;
    return 'undef' unless defined $val;

    # numbers should look like number and not start with a 0 (no support
    # for octals)
    return $val if is_number($val) && $val !~ /^0+/;
    $self->_emit_string($val);
}

sub _emit_string {
    my ($self, $str) = @_;
    B::perlstring($str);
}

1;
