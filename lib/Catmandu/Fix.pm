package Catmandu::Fix::Loader;

use Catmandu::Sane;
use Catmandu::Util qw(:is require_package read_file);

my @fixes;
my @stack;

sub load_fixes {
    @fixes = ();
    @stack = ();
    for my $fix (@{$_[0]}) {
        if (is_able($fix, 'fix')) {
            push @fixes, $fix;
        } elsif (is_string($fix)) {
            if (-r $fix) {
                $fix = read_file($fix);
            }
            eval "package Catmandu::Fix::Loader::Env;$fix;1" or confess $@;
        }
    }
    confess "if without end" if @stack;
    [@fixes];
}

sub _add_fix {
    my ($fix, @args) = @_;

    if ($fix eq 'end') {
        $fix = pop @stack || confess "end without if";
        if (@stack) {
            push @{$stack[-1]->fixes}, $fix;
        } else {
            push @fixes, $fix;
        }
    }
    elsif ($fix =~ s/^if_//) {
        $fix = require_package($fix, 'Catmandu::FixCondition')->new(@args);
        push @stack, $fix;
    }
    elsif ($fix =~ s/^unless_//) {
        $fix = require_package($fix, 'Catmandu::FixCondition')->new(@args);
        $fix->invert(1);
        push @stack, $fix;
    }
    else {
        $fix = require_package($fix, 'Catmandu::Fix')->new(@args);
        if (@stack) {
            push @{$stack[-1]->fixes}, $fix;
        } else {
            push @fixes, $fix;
        }
    }
}

package Catmandu::Fix::Loader::Env;

use strict;
use warnings FATAL => 'all';

sub AUTOLOAD {
    my ($fix) = our $AUTOLOAD =~ /::(\w+)$/;

    my $sub = sub { Catmandu::Fix::Loader::_add_fix($fix, @_); return };

    { no strict 'refs'; *$AUTOLOAD = $sub };

    $sub->(@_);
}

sub DESTROY {}

package Catmandu::Fix;

use Catmandu::Sane;
use Catmandu::Util qw(:is :string);
use Clone qw(clone);

sub _eval_emit { use warnings FATAL => 'all'; eval $_[0] }

use Moo;
use Perl::Tidy ();
use B ();
use Catmandu::Fix;

has tidy      => (is => 'ro');
has fixer     => (is => 'ro', lazy => 1, init_arg => undef, builder => 1);
has _num_vars => (is => 'rw', lazy => 1, init_arg => undef, default => sub { 0; });
has _captures => (is => 'ro', lazy => 1, init_arg => undef, default => sub { +{}; });
has var       => (is => 'ro', lazy => 1, init_arg => undef, builder => 'generate_var');
has fixes     => (is => 'ro', required => 1, trigger => 1);

sub _trigger_fixes {
    my ($self) = @_;
    my $fixes = $self->fixes;
    my $loaded_fixes = Catmandu::Fix::Loader::load_fixes($fixes);
    splice(@$fixes, 0, @$fixes, @$loaded_fixes);
}

sub _build_fixer {
    my ($self) = @_;
    local $@;
    _eval_emit($self->emit, $self->_captures) or die $@;
}

sub fix {
    my ($self, $data) = @_;

    my $fixer = $self->fixer;

    if (is_hash_ref($data)) {
        return $fixer->($data);
    }
    if (is_instance($data)) {
        return $data->map(sub { $fixer->($_) });
    }
    if (is_code_ref($data)) {
        return sub { $fixer->($data->() // return) };
    }
    if (is_array_ref($data)) {
        return [ map { $fixer->($_) } @$data ];
    }

    confess "must be hashref, arrayref, coderef or iterable object";
}

sub generate_var {
    my ($self) = @_;
    my $n = $self->_num_vars;
    $self->_num_vars($n + 1);
    "\$__$n";
}

sub emit {
    my ($self) = @_;
    my $var = $self->var;
    my $captures = $self->_captures;
    my $perl = "";

    $perl .= "sub {";
    $perl .= $self->emit_declare_vars($var, '$_[0]');
    for my $fix (@{$self->fixes}) {
        $perl .= $self->emit_fix($fix);
    }
    $perl .= "return $var;";
    $perl .= "};";

    if (%$captures) {
        my @captured_vars = map {
            $self->emit_declare_vars($_, '$_[1]->{'.$self->emit_string($_).'}');
        } keys %$captures;
        $perl = join '', @captured_vars, $perl;
    }

    return $perl unless $self->tidy;

    my $tidy_perl = "";
    my $err = "";

    my $has_err = Perl::Tidy::perltidy(
        argv        => "-npro -se",
        source      => \$perl,
        destination => \$tidy_perl,
        stderr      => \$err,
    ) ;
    if ($has_err) {
        confess $err;
    }

    $tidy_perl;
}

sub emit_fix {
    my ($self, $fix) = @_;
    my $perl = "";

    if ($fix->can('emit')) {
        if ($fix->isa('Catmandu::FixCondition')) {
            my $cond = $fix->invert ? "unless" : "if";
            $perl .= "$cond (".$fix->emit($self).") {";
            for my $f (@{$fix->fixes}) {
                $perl .= $self->emit_fix($f);
            }
            $perl .= "}";
        } else {
            $perl .= $self->emit_new_scope;
            $perl .= $fix->emit($self);
            $perl .= $self->emit_end_scope;
        }
    } else {
        my $var = $self->var;
        my $fix_var = $self->generate_var;
        $self->_captures->{$fix_var} = $fix;
        $perl .= "${var} = ${fix_var}->fix(${var});";
    }

    $perl;
}

sub emit_value {
    my ($self, $val) = @_;
    is_number($val) ? $val : $self->emit_string($val);
}

sub emit_string {
    my ($self, $str) = @_;
    B::perlstring($str);
}

sub emit_declare_vars {
    my ($self, $var, $val) = @_;
    $var = "(".join(", ", @$var).")" if ref $var;
    $val = "(".join(", ", @$val).")" if ref $val;
    if (defined $val) {
        return "my ${var} = ${val};";
    }
    "my ${var};";
}

sub emit_new_scope {
    "do {";
}

sub emit_end_scope {
    "};";
}

sub emit_foreach {
    my ($self, $var, $cb) = @_;
    my $perl = "";
    my $v = $self->generate_var;
    $perl .= "foreach (\@{${var}}) {";
    $perl .= $self->emit_declare_vars($v, '$_');
    $perl .= $cb->($v);
    $perl .= "}";
    $perl;
}

sub emit_foreach_key {
    my ($self, $var, $cb) = @_;
    my $perl = "";
    my $v = $self->generate_var;
    $perl .= "foreach (keys(\%{${var}})) {";
    $perl .= $self->emit_declare_vars($v, '$_');
    $perl .= $cb->($v);
    $perl .= "}";
    $perl;
}

sub emit_walk_path {
    my ($self, $var, $keys, $cb) = @_;

    $keys = [@$keys]; # protect keys

    if (@$keys) { # protect $var
        my $v = $self->generate_var;
        $self->emit_new_scope
            . $self->emit_declare_vars($v, $var)
            . $self->_unsafe_emit_walk_path($v, $keys, $cb)
            . $self->emit_end_scope;
    } else {
        $cb->($var);
    }
}

sub _unsafe_emit_walk_path {
    my ($self, $var, $keys, $cb) = @_;

    my $key  = shift @$keys;
    my $perl = "";

    if ($key =~ /^\d+$/) {
        $perl .= qq|if (is_hash_ref(${var})) {|;
        $perl .= qq|${var} = ${var}->{\"${key}\"};|;
        if (@$keys) {
            $perl .= $self->_unsafe_emit_walk_path($var, $keys, $cb);
        } elsif ($cb) {
            $perl .= $cb->($var);
        }
        $perl .= qq|} elsif (is_array_ref(${var}) && \@{${var}} > ${key}) {|;
        $perl .= qq|${var} = ${var}->[${key}];|;
        if (@$keys) {
            $perl .= $self->_unsafe_emit_walk_path($var, $keys, $cb);
        } elsif ($cb) {
            $perl .= $cb->($var);
        }
        $perl .= qq|}|;
    }
    elsif ($key eq '*') {
        my $v = $self->generate_var;
        $perl .= qq|if (is_array_ref(${var})) {|;
        $perl .= $self->emit_foreach($var, sub {
            my $v = shift;
            if (@$keys) {
                return $self->_unsafe_emit_walk_path($v, $keys, $cb);
            } elsif ($cb) {
                return $cb->($v);
            } else {
                return "";
            }
        });
        $perl .= "}";
    }
    else {
        if ($key eq '$first') {
            $perl .= qq|if (is_array_ref(${var}) && \@{${var}}) {|;
            $perl .= qq|${var} = ${var}->[0];|;
        }
        elsif ($key eq '$last') {
            $perl .= qq|if (is_array_ref(${var}) && \@{${var}}) {|;
            $perl .= qq|${var} = ${var}->[\@{${var}} - 1];|;
        } else {
            $key = $self->emit_string($key);
            $perl .= qq|if (is_hash_ref(${var})) {|;
            $perl .= qq|${var} = ${var}->{${key}};|;
        }
        if (@$keys) {
            $perl .= $self->_unsafe_emit_walk_path($var, $keys, $cb);
        } elsif ($cb) {
            $perl .= $cb->($var);
        }
        $perl .= "}";
    }

    $perl;
}

sub emit_get_key {
    my ($self, $var, $key, $cb) = @_;
    my $perl = "";

    if ($key =~ /^\d+$/) {
        $perl .= "if (is_hash_ref(${var}) && exists(${var}->{\"${key}\"})) {";
        $perl .= $cb->("${var}->{\"${key}\"}");
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
        my $i = $self->generate_var;
        $perl .= "if (is_array_ref(${var})) {";
        $perl .= "for (my ${i} = 0; ${i} < \@{${var}}; ${i}++) {";
        $perl .= $cb->("${var}->[${i}]");
        $perl .= "}}";
    }
    else {
        $key = $self->emit_string($key);
        $perl .= "if (is_hash_ref(${var}) && exists(${var}->{${key}})) {";
        $perl .= $cb->("${var}->{${key}}");
        $perl .= "}";
    }

    $perl;
}

sub emit_set_key {
    my ($self, $var, $key, $val) = @_;
    my $perl = "";

    if ($key =~ /^\d+$/) {
        $perl .= "if (is_hash_ref(${var})) {";
        $perl .= "${var}->{\"${key}\"} = $val;";
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
        my $i = $self->generate_var;
        $perl .= "if (is_array_ref(${var})) {";
        $perl .= "for (my ${i} = 0; ${i} < \@{${var}}; ${i}++) {";
        $perl .= "${var}->[${i}] = $val;";
        $perl .= "}}";
    }
    else {
        $key = $self->emit_string($key);
        $perl .= "if (is_hash_ref(${var})) {";
        $perl .= "${var}->{${key}} = $val;";
        $perl .= "}";
    }

    $perl;
}

sub emit_delete_key {
    my ($self, $var, $key) = @_;

    my $perl = "";

    if ($key =~ /^\d+$/) {
        return "if (is_hash_ref(${var})) {
    delete(${var}->{\"${key}\"});
} elsif (is_array_ref(${var}) && \@{${var}} > ${key}) {
    splice(\@{${var}}, ${key}, 1);
}
";
    }
    elsif ($key eq '$first') {
        $perl .= "if (is_array_ref(${var}) && \@{${var}}) {";
        $perl .= "splice(\@{${var}}, 0, 1);";
        $perl .= "}";
    }
    elsif ($key eq '$last') {
        $perl .= "if (is_array_ref(${var}) && \@{${var}}) {";
        $perl .= "splice(\@{${var}}, \@{${var}} - 1, 1);";
        $perl .= "}";
    }
    elsif ($key eq '*') {
        $perl .= "if (is_array_ref(${var}) && \@{${var}}) {";
        $perl .= "splice(\@{${var}}, 0, \@{${var}});";
        $perl .= "}";
    }
    else {
        $key = $self->emit_string($key);
        $perl .= "if (is_hash_ref(${var})) {";
        $perl .= "delete(${var}->{${key}});";
        $perl .= "}";
    }

    $perl;
}

sub emit_retain_key {
    my ($self, $var, $key) = @_;

    my $perl = "";

    if ($key =~ /^\d+$/) {
        $perl .= "if (is_hash_ref(${var})) {";
        $perl .= $self->emit_foreach_key($var, sub {
            my $v = shift;
            "delete(${var}->{${v}}) if ${v} ne ${key};";
        });
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
        $perl .= $self->emit_foreach_key($var, sub {
            my $v = shift;
            "delete(${var}->{${v}}) if ${v} ne ${key};";
        });
        $perl .= "}";
    }

    $perl;
}

sub emit_clone {
    my ($self, $var) = @_;
    "${var} = clone(${var});";
}

=head1 NAME

Catmandu::Fix - a Catmandu class used for data crunching

=head1 SYNOPSIS

    use Catmandu::Fix;

    my $fixer = Catmandu::Fix->new(fixes => ['upcase("job")','remove_field("test")']);

    or 

    my $fixer = Catmandu::Fix->new(fixes => ['fix_file.txt']);

    my $arr  = $fixer->fix([ ... ]);
    my $hash = $fixer->fix({ ... });
  
    my $it = Catmandu::Importer::YAML(file => '...');
    $fixer->fix($it)->each(sub {
	...
    });

=head1 DESCRIPTION

Catmandu::Fix-es can be use for easy data manipulation by non programmers. Using a
small Perl DSL language end-users can use Fix routines to manipulate data objects.
A plain text file of fixes can be created to specify all the routines needed to
tranform the data into the desired format.

=head1 PATHS

All the Fix routines in Catmandu::Fix use a TT2 type reference to point to values
in a Perl Hash. E.g. 'foo.2.bar' is a key 'bar' which is the 3-rd value of the 
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
 add_field('mods.titleInfo.$append.title', 'a title');

 # Create { mods => { titleInfo => [ { 'title' => 'a title' } , { 'title' => 'another title' }] } };
 add_field('mods.titleInfo.$append.title', 'another title');

 # Create { mods => { titleInfo => [ { 'title' => 'foo' } , { 'title' => 'another title' }] } };
 add_field('mods.titleInfo.$first.title', 'foo');

 # Create { mods => { titleInfo => [ { 'title' => 'foo' } , { 'title' => 'bar' }] } };
 add_field('mods.titleInfo.$last.title', 'bar');

=head1 METHODS

=head2 new(fixes => [ FIX , ...])

Create a new Catmandu::Fix which will execute every FIX into a consecutive order. A
FIX can be the name of a Catmandu::Fix::* routine or the path to a plain text file
containing all the fixes to be executed.

=head2 fix(HASH)

Execute all the fixes on a HASH. Returns the fixed HASH.

=head2 fix(ARRAY)

Execute all the fixes on every element in the ARRAY. Returns an ARRAY of fixes.

=head2 fix(Catmandu::Iterator)

Execute all the fixes on every item in an Catmandu::Iterator. Returns a (lazy) iterator
on all the fixes.

=head2 fix(sub {})

Executes all the fixes on a generator function. Returns a new generator with fixed data.

=head1 SEE ALSO

L<Catmandu::Fix::add_field>

=cut

1;
