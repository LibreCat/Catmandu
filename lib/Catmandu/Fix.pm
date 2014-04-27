package Catmandu::Fix;

use Catmandu::Sane;
use Catmandu;
use Catmandu::Util qw(:is :string :misc);
use Clone qw(clone);

sub _eval_emit {
    use warnings FATAL => 'all';
    eval $_[0];
}

use Moo;
use Catmandu::Fix::Parser;
use Data::Dumper ();
use B ();

with 'MooX::Log::Any';

has tidy        => (is => 'ro');
has parser      => (is => 'lazy');
has fixer       => (is => 'lazy', init_arg => undef);
has _num_labels => (is => 'rw', lazy => 1, init_arg => undef, default => sub { 0; });
has _num_vars   => (is => 'rw', lazy => 1, init_arg => undef, default => sub { 0; });
has _captures   => (is => 'ro', lazy => 1, init_arg => undef, default => sub { +{}; });
has var         => (is => 'ro', lazy => 1, init_arg => undef, builder => 'generate_var');
has fixes       => (is => 'ro', required => 1, trigger => 1);
has _reject     => (is => 'ro', init_arg => undef, default => sub { +{} });
has _reject_var => (is => 'ro', lazy => 1, init_arg => undef, builder => '_build_reject_var');

sub _build_parser {
    Catmandu::Fix::Parser->new;
}

sub _trigger_fixes {
    my ($self) = @_;
    my $fixes = $self->fixes;
    my $parsed_fixes = [];
    for my $fix (@$fixes) {
        if (ref $fix) {
            push @$parsed_fixes, $fix;
        } else {
            push @$parsed_fixes, @{$self->parser->parse($fix)};
        }
    }
    splice(@$fixes, 0, @$fixes, @$parsed_fixes);
}

sub _build_fixer {
    my ($self) = @_;
    local $@;
    _eval_emit($self->emit, $self->_captures) or Catmandu::Error->throw($@);
}

sub _build_reject_var {
    my ($self) = @_;
    $self->capture($self->_reject);
}

sub fix {
    my ($self, $data) = @_;

    my $fixer = $self->fixer;

    if (is_hash_ref($data)) {
        my $d = $fixer->($data);
        return if $d == $self->_reject;
        return $d;
    }

    if (is_instance($data)) {
        return $data->map(sub { $fixer->($_[0]) })
                    ->reject(sub { $_[0] == $self->_reject });
    }

    if (is_code_ref($data)) {
        return sub {
            for (;;) {
                my $d = $fixer->($data->() // return);
                next if $d == $self->_reject;
                return $d;
            }
        };
    }

    if (is_array_ref($data)) {
        return [ grep { $_ != $self->_reject } map { $fixer->($_) } @$data ];
    }

    Catmandu::BadArg->throw("must be hashref, arrayref, coderef or iterable object");
}

sub generate_var {
    my ($self) = @_;
    my $n = $self->_num_vars;
    $self->_num_vars($n + 1);
    "\$__$n";
}

sub capture {
    my ($self, $capture) = @_;
    my $var = $self->generate_var;
    $self->_captures->{$var} = $capture;
    $var;
}

sub emit {
    my ($self) = @_;
    my $var = $self->var;
    my $err = $self->generate_var;
    my $captures = $self->_captures;
    my $perl = "";

    $perl .= "sub {";
    $perl .= $self->emit_declare_vars($var, '$_[0]');
    $perl .= "eval {";
    for my $fix (@{$self->fixes}) {
        $perl .= $self->emit_fix($fix);
    }
    $perl .= "${var};";
    $perl .= "} or do {";
    $perl .= $self->emit_declare_vars($err, '$@');
    # TODO throw Catmandu::Error
    $perl .= qq|die ${err}.Data::Dumper->Dump([${var}], [qw(data)]);|;
    $perl .= "};";
    $perl .= "};";

    if (%$captures) {
        my @captured_vars = map {
            $self->emit_declare_vars($_, '$_[1]->{'.$self->emit_string($_).'}');
        } keys %$captures;
        $perl = join '', @captured_vars, $perl;
    }

    if ($self->tidy) {
        require Perl::Tidy;

        my $tidy_perl = "";
        my $err = "";
        my $log = "";

        my $has_err = Perl::Tidy::perltidy(
            argv        => "-se",
            source      => \$perl,
            destination => \$tidy_perl,
            logfile     => \$log,
            stderr      => \$err,
        );
        if ($has_err) {
            Catmandu::Error->throw($err);
        }

        $perl = $tidy_perl;
    }

    $self->log->debug($perl);

    $perl;
}

sub emit_reject {
    my ($self) = @_;
    my $reject_var = $self->_reject_var;
    "return $reject_var;";
}

sub emit_fix {
    my ($self, $fix) = @_;
    my $perl;

    if ($fix->can('emit')) {
        $perl = $self->emit_block(sub {
            my ($label) = @_;
            $fix->emit($self, $label);
        });
    } else {
        my $var = $self->var;
        my $ref = $self->generate_var;
        $self->_captures->{$ref} = $fix;
        $perl = "${var} = ${ref}->fix(${var});";
    }

    $perl;
}

sub emit_block {
    my ($self, $cb) = @_;
    my $n = $self->_num_labels;
    $self->_num_labels($n + 1);
    my $label = "__FIX__${n}";
    my $perl = "${label}: {";
    $perl .= $cb->($label);
    $perl .= "};";
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
    "{";
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
        $self->emit_declare_vars($v, $var)
            . $self->_emit_walk_path($v, $keys, $cb);
    } else {
        $cb->($var);
    }
}

sub _emit_walk_path {
    my ($self, $var, $keys, $cb) = @_;

    @$keys || return $cb->($var);

    my $key = shift @$keys;
    my $str_key = $self->emit_string($key);
    my $perl = "";

    if ($key =~ /^\d+$/) {
        $perl .= "if (is_hash_ref(${var})) {";
        $perl .= "${var} = ${var}->{${str_key}};";
        $perl .= $self->_emit_walk_path($var, [@$keys], $cb);
        $perl .= "} elsif (is_array_ref(${var}) && \@{${var}} > ${key}) {";
        $perl .= "${var} = ${var}->[${key}];";
        $perl .= $self->_emit_walk_path($var, [@$keys], $cb);
        $perl .= "}";
    }
    elsif ($key eq '*') {
        my $v = $self->generate_var;
        $perl .= "if (is_array_ref(${var})) {";
        $perl .= $self->emit_foreach($var, sub {
            return $self->_emit_walk_path(shift, $keys, $cb);
        });
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

    my $key = shift @$keys;
    my $str_key = $self->emit_string($key);
    my $perl = "";

    if ($key =~ /^\d+$/) {
        my $v1 = $self->generate_var;
        my $v2 = $self->generate_var;
        $perl .= "if (is_hash_ref(${var})) {";
        $perl .= "my ${v1} = ${var};";
        $perl .= $self->_emit_create_path("${v1}->{${str_key}}", [@$keys], $cb);
        $perl .= "} elsif (is_maybe_array_ref(${var})) {";
        $perl .= "my ${v2} = ${var} //= [];";
        $perl .= $self->_emit_create_path("${v2}->[${key}]", [@$keys], $cb);
        $perl .= "}";
    }
    elsif ($key eq '*') {
        my $v1 = $self->generate_var;
        my $v2 = $self->generate_var;
        $perl .= "if (is_array_ref(${var})) {";
        $perl .= "my ${v1} = ${var};";
        $perl .= "for (my ${v2} = 0; ${v2} < \@{${v1}}; ${v2}++) {";
        $perl .= $self->_emit_create_path("${v1}->[${v2}]", $keys, $cb);
        $perl .= "}";
        $perl .= "}";
    }
    else {
        my $v = $self->generate_var;
        if ($key eq '$first' || $key eq '$last' || $key eq '$prepend' || $key eq '$append') {
            $perl .= "if (is_maybe_array_ref(${var})) {";
            $perl .= "my ${v} = ${var} //= [];";
            if ($key eq '$first') {
                    $perl .= $self->_emit_create_path("${v}->[0]", $keys, $cb);
            }
            elsif ($key eq '$last') {
                $perl .= "if (\@${v}) {";
                $perl .= $self->_emit_create_path("${v}->[\@${v} - 1]", [@$keys], $cb);
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
                $perl .= $self->_emit_create_path("${v}->[\@${v}]", $keys, $cb);
            }
            $perl .= "}";
        }
        else {
            $perl .= "if (is_maybe_hash_ref(${var})) {";
            $perl .= "my ${v} = ${var} //= {};";
            $perl .= $self->_emit_create_path("${v}->{${str_key}}", $keys, $cb);
            $perl .= "}";
        }
    }

    $perl;
}

sub emit_get_key {
    my ($self, $var, $key, $cb) = @_;

    my $str_key = $self->emit_string($key);
    my $perl = "";

    if ($key =~ /^\d+$/) {
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
        my $i = $self->generate_var;
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
    my $perl = "";
    my $str_key = $self->emit_string($key);

    if ($key =~ /^\d+$/) {
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
        my $i = $self->generate_var;
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
    my $perl = "";
    my $vals;
    if ($cb) {
        $vals = $self->generate_var;
        $perl = $self->emit_declare_vars($vals, '[]');
    }

    if ($key =~ /^\d+$/) {
        $perl .= "if (is_hash_ref(${var}) && exists(${var}->{${str_key}})) {";
        $perl .= "push(\@{${vals}}, "                     if $cb;
        $perl .= "delete(${var}->{${str_key}})";
        $perl .= ")"                                      if $cb;
        $perl .= ";";
        $perl .= "} elsif (is_array_ref(${var}) && \@{${var}} > ${key}) {";
        $perl .= "push(\@{${vals}}, "                     if $cb;
        $perl .= "splice(\@{${var}}, ${key}, 1)";
        $perl .= ")"                                      if $cb;
    }
    elsif ($key eq '$first' || $key eq '$last' || $key eq '*') {
        $perl .= "if (is_array_ref(${var}) && \@{${var}}) {";
        $perl .= "push(\@{${vals}}, "                     if $cb;
        $perl .= "splice(\@{${var}}, 0, 1)"               if $key eq '$first';
        $perl .= "splice(\@{${var}}, \@{${var}} - 1, 1)"  if $key eq '$last';
        $perl .= "splice(\@{${var}}, 0, \@{${var}})"      if $key eq '*';
        $perl .= ")"                                      if $cb;
    }
    else {
        $perl .= "if (is_hash_ref(${var}) && exists(${var}->{${str_key}})) {";
        $perl .= "push(\@{${vals}}, "                    if $cb;
        $perl .= "delete(${var}->{${str_key}})";
        $perl .= ")"                                     if $cb;
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
            "if ($v ne ${key}) {".
            "delete(${var}->{${v}});".
            "}";
        });
        $perl .= "}";
    }

    $perl;
}

sub emit_clone {
    my ($self, $var) = @_;
    "${var} = clone(${var});";
}

sub split_path {
    my ($self, $path) = @_;
    return [ split /[\/\.]/, $path ];
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

    or

    use Catmandu::Fix::upcase as => 'my_upcase';
    use Catmandu::Fix::remove_field as => 'my_remove';

    my $hash = { 'job' => 'librarian' , deep => { nested => '1'} };

    my_upcase($hash,'job');
    my_remove($hash,'deep.nested');

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

Execute all the fixes on every item in an L<Catmandu::Iterator>. Returns a
(lazy) iterator on all the fixes.

=head2 fix(sub {})

Executes all the fixes on a generator function. Returns a new generator with fixed data.

=head2 log

Return the current logger.

=cut

1;
