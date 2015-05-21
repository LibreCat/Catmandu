package Catmandu::Fix::Parser;

=head1 NAME

Catmandu::Fix::Parser - the parser of the Catmandu::Fix language

=head1 SYNOPSIS

    use Catmandu::Sane;
    use Catmandu::Fix::Parser;
    use Catmandu::Fix;

    use Data::Dumper;

    my $parser = Catmandu::Fix::Parser->new;

    my $fixes;

    try {
        $fixes = $parser->parse(<<EOF);
    add_field(test,123)
    EOF
    }
    catch {
        printf "[%s]\nscript:\n%s\nerror: %s\n" 
                , ref($_) 
                , $_->source
                , $_->message;
    };

    my $fixer = Catmandu::Fix->new(fixes => $fixes);

    print Dumper($fixer->fix({}));

=head1 DESCRIPTION

Programmers are discouraged to use the Catmandu::Parser directly in code but
use the Catmandu package that provides the same functionality:

    use Catmandu;

    my $fixer = Catmandu->fixer(<<EOF);
    add_field(test,123)
    EOF

    print Dumper($fixer->fix({}));

=head1 METHODS

=head2 new()

Create a new Catmandu::Fix parser

=head2 parse($string)

=head2 parse($file)

Reads a string or a file and returns a blessed object with parsed
Catmandu::Fixes. Throws an Catmandu::ParseError on failure.

=head1 SEE ALSO

L<Catmandu::Fix>

Or consult the webpages below for more information on the Catmandu::Fix language

http://librecat.org/Catmandu/#fixes
http://librecat.org/Catmandu/#fix-language

=cut

use Catmandu::Sane;
use Marpa::R2;
use Data::Dumper;
use Catmandu;
use Catmandu::Util qw(check_value is_instance is_able require_package);
use File::Slurp::Tiny;
use Moo;

with 'Catmandu::Logger';

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
             | doset      action => ::first
             | do         action => ::first
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

doset ::= ('doset') bind fixes ('end') bless => DoSet

do ::= ('do') bind fixes ('end') bless => Do

bind ::= name ('(') args (')') bless => Bind

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

discard ~ comment | whitespace | old_terminator

whitespace ~ [\s]+

comment       ~ '#' comment_chars
comment_chars ~ comment_char*
comment_char  ~ [^\n]

old_terminator ~ ';'

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
        $source = File::Slurp::Tiny::read_file($source,binmode => ':encoding(UTF-8)');
    }

    my $val;

    try {
        my $recognizer = Marpa::R2::Scanless::R->new({grammar => $grammar});
        $recognizer->read(\$source);
        $val = ${$recognizer->value};

        $self->log->debugf(Dumper($val)) if $self->log->is_debug;

        [map {$_->reify} @$val];
    } catch {
       if (is_instance($_, 'Catmandu::Error')) {
           $_->set_source($source) if is_able($_, 'set_source');
           $_->throw;
       }
       Catmandu::FixParseError->throw(message => $_, source => $source);
    };
}

sub _build_fix {
   my ($name, $ns, @args) = @_;
   my $pkg;
   try {
    $pkg = require_package($name, $ns); 
   } catch_case [
       'Catmandu::NoSuchPackage' => sub {
           Catmandu::NoSuchFixPackage->throw(
               message      => "No such fix package: $name",
               package_name => $_->package_name,
               fix_name     => $name,
           );
       },
   ];
   try {
       $pkg->new(@args); 
   } catch {
       $_->throw if is_instance($_, 'Catmandu::Error');
       Catmandu::BadFixArg->throw(
           message      => $_,
           package_name => $pkg,
           fix_name     => $name,
       );
   };
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
    Catmandu::Fix::Parser::_build_fix($name, 'Catmandu::Fix',
        map { $_->reify } @$args);
}

sub Catmandu::Fix::Parser::Condition::reify {
    my $name = $_[0]->[0];
    my $args = $_[0]->[1];
    Catmandu::Fix::Parser::_build_fix($name, 'Catmandu::Fix::Condition',
        map { $_->reify } @$args);
}

sub Catmandu::Fix::Parser::OldCondition::reify {
    my $name = $_[0]->[0];
    my $args = $_[0]->[1];
    $name =~ s/^(?:if|unless)_//;
    Catmandu::Fix::Parser::_build_fix($name, 'Catmandu::Fix::Condition',
        map { $_->reify } @$args);
}

sub Catmandu::Fix::Parser::DoSet::reify {
    my $bind       = $_[0]->[0]->reify;
    my $do_fixes   = $_[0]->[1];
    $bind->return(1);
    $bind->fixes([map { $_->reify } @$do_fixes]);
    $bind;
}

sub Catmandu::Fix::Parser::Do::reify {
    my $bind       = $_[0]->[0]->reify;
    my $do_fixes   = $_[0]->[1];
    $bind->return(0);
    $bind->fixes([map { $_->reify } @$do_fixes]);
    $bind;
}

sub Catmandu::Fix::Parser::Bind::reify {
    my $name = $_[0]->[0];
    my $args = $_[0]->[1];
    Catmandu::Fix::Parser::_build_fix($name, 'Catmandu::Fix::Bind',
        map { $_->reify } @$args);
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

    $str =~ s{\\'}{'}gxms;

    $str;
}

sub Catmandu::Fix::Parser::BareString::reify {
    $_[0]->[0];
}

sub Catmandu::Fix::Parser::Int::reify {
    int($_[0]->[0]);
}

1;
