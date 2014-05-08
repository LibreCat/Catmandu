package Catmandu::Fix::Parser;

use Catmandu::Sane;
use Marpa::R2;
use Data::Dumper;
use Catmandu;
use Catmandu::Util qw(check_value read_file);
use Moo;

with 'MooX::Log::Any';

my $GRAMMAR = <<'GRAMMAR';
:default ::= action => ::array
:start ::= fixes
:discard ~ discard

fixes ::= expression*

expression ::= old_if     action => ::first
             | old_unless action => ::first
             | if         action => ::first
             | if_else    action => ::first
             | unless     action => ::first
             | select     action => ::first
             | reject     action => ::first
             | fix        action => ::first

old_if ::= old_if_condition fixes ('end()') bless => IfElse

old_unless ::= old_unless_condition fixes ('end()') bless => Unless

if ::= ('if') condition fixes ('end') bless => IfElse

if_else ::= ('if') condition fixes ('else') fixes ('end') bless => IfElse

unless ::= ('unless') condition fixes ('end') bless => Unless

select ::= ('select') condition bless => Select

reject ::= ('reject') condition bless => Reject

old_if_condition ::= old_if_name ('(') args (')') bless => OldCondition

old_unless_condition ::= old_unless_name ('(') args (')') bless => OldCondition

condition ::= name ('(') args (')') bless => Condition

fix ::= name ('(') args (')') bless => Fix

args ::= arg* separator => sep

arg ::= int         bless => Int
      | qq_string   bless => DoubleQuotedString
      | q_string    bless => SingleQuotedString
      | bare_string bless => BareString

old_if_name ~ 'if_' [a-z] name_rest

old_unless_name ~ 'unless_' [a-z] name_rest

name      ~ [a-z] name_rest
name_rest ~ [_\da-zA-Z]*

int ~ digits
    | '-' digits

digits ~ [\d]+

qq_string ~ '"' qq_chars '"'
qq_chars  ~ qq_char*
qq_char   ~ [^"] | '\"'

q_string ~ ['] q_chars [']
q_chars  ~ q_char*
q_char   ~ [^'] | '\' [']

bare_string ~ [^\s\\\,;:=>()"']+

old_terminator ~ ';'

whitespace ~ [\s]+

discard ~ whitespace | old_terminator

sep ~ [,:]
    | '=>'
GRAMMAR

sub parse {
    state $grammar = Marpa::R2::Scanless::G->new({
        bless_package  => __PACKAGE__,
        source => \$GRAMMAR,
    });

    my ($self, $source) = @_;

    check_value($source);

    if ($source =~ /[^\s]/ && $source !~ /\(/) {
        $source = read_file($source);
    }

    my $recognizer = Marpa::R2::Scanless::R->new({grammar => $grammar});
    $recognizer->read(\$source);
    my $val = ${$recognizer->value};

    $self->log->debugf(Dumper($val)) if $self->log->is_debug();

    [ map {$_->reify} @$val ];
}

sub Catmandu::Fix::Parser::IfElse::reify {
    my $cond       = $_[0]->[0]->reify;
    my $pass_fixes = $_[0]->[1];
    my $fail_fixes = $_[0]->[2];
    $cond->pass_fixes([map { $_->reify } @$pass_fixes]);
    $cond->fail_fixes([map { $_->reify } @$fail_fixes]) if $fail_fixes;
    $cond;
}

sub Catmandu::Fix::Parser::Unless::reify {
    my $cond       = $_[0]->[0]->reify;
    my $fail_fixes = $_[0]->[1];
    $cond->fail_fixes([map { $_->reify } @$fail_fixes]);
    $cond;
}

sub Catmandu::Fix::Parser::Select::reify {
    my $cond = $_[0]->[0]->reify;
    $cond->fail_fixes([Catmandu::Util::require_package('Catmandu::Fix::reject')->new]);
    $cond;
}

sub Catmandu::Fix::Parser::Reject::reify {
    my $cond = $_[0]->[0]->reify;
    $cond->pass_fixes([Catmandu::Util::require_package('Catmandu::Fix::reject')->new]);
    $cond;
}

sub Catmandu::Fix::Parser::Fix::reify {
    my $name = $_[0]->[0];
    my $args = $_[0]->[1];
    Catmandu::Util::require_package($name, 'Catmandu::Fix')
        ->new(map { $_->reify } @$args);
}

sub Catmandu::Fix::Parser::Condition::reify {
    my $name = $_[0]->[0];
    my $args = $_[0]->[1];
    Catmandu::Util::require_package($name, 'Catmandu::Fix::Condition')
        ->new(map { $_->reify } @$args);
}

sub Catmandu::Fix::Parser::OldCondition::reify {
    my $name = $_[0]->[0];
    my $args = $_[0]->[1];
    $name =~ s/^(?:if|unless)_//;
    Catmandu::Util::require_package($name, 'Catmandu::Fix::Condition')
        ->new(map { $_->reify } @$args);
}

sub Catmandu::Fix::Parser::DoubleQuotedString::reify {
    my $str = $_[0]->[0];

    $str = substr($str, 1, length($str) - 2);

    if (index($str, '\\') != -1) {
        $str =~ s/\\u([0-9A-Fa-f]{4})/chr(hex($1))/egxms;
        $str =~ s/\\n/\n/gxms;
        $str =~ s/\\r/\r/gxms;
        $str =~ s/\\b/\b/gxms;
        $str =~ s/\\f/\f/gxms;
        $str =~ s/\\t/\t/gxms;
        $str =~ s/\\\\/\\/gxms;
        $str =~ s{\\/}{/}gxms;
        $str =~ s{\\"}{"}gxms;
    }

    $str;
}

sub Catmandu::Fix::Parser::SingleQuotedString::reify {
    my $str = $_[0]->[0];

    $str = substr($str, 1, length($str) - 2);

    if (index($str, '\\') != -1) {
        $str =~ s/\\u([0-9A-Fa-f]{4})/chr(hex($1))/egxms;
        $str =~ s/\\n/\n/gxms;
        $str =~ s/\\r/\r/gxms;
        $str =~ s/\\b/\b/gxms;
        $str =~ s/\\f/\f/gxms;
        $str =~ s/\\t/\t/gxms;
        $str =~ s/\\\\/\\/gxms;
        $str =~ s{\\/}{/}gxms;
        $str =~ s{\\'}{'}gxms;
    }

    $str;
}

sub Catmandu::Fix::Parser::BareString::reify {
    $_[0]->[0];
}

sub Catmandu::Fix::Parser::Int::reify {
    int($_[0]->[0]);
}

1;

