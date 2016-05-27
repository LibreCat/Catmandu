package Catmandu::Fix::Parser;

use Catmandu::Sane;

our $VERSION = '1.0201_01';

use Catmandu::Util qw(check_value is_instance is_able require_package);
use Moo;
use namespace::clean;

extends 'Parser::MGC';

sub FOREIGNBUILDARGS {
    my ($class, $opts) = @_;
    $opts->{toplevel} = 'parse_statements';
    %$opts;
}

sub parse {
    my ($self, $source) = @_;

    check_value($source);

    try {
        $self->from_string($source);
    }
    catch {
        my $err = $_;
        if (is_instance($err, 'Catmandu::Error')) {
            $err->set_source($source) if is_able($err, 'set_source');
            $err->throw;
        }
        Catmandu::FixParseError->throw(message => $err, source => $source,);
    };
}

sub pattern_comment {
    qr/#[^\n]*/;
}

sub parse_statements {
    my ($self) = @_;
    $self->sequence_of('parse_statement');
}

sub parse_statement {
    my ($self) = @_;
    my $statement
        = $self->any_of('parse_filter', 'parse_condition', 'parse_bind',
        'parse_fix',);

    # support deprecated separator
    $self->maybe_expect(';');
    $statement;
}

sub parse_condition {
    my ($self) = @_;
    my $type       = $self->token_kw('if', 'unless');
    my $name       = $self->parse_name;
    my $args       = $self->parse_arguments;
    my $fixes      = $self->sequence_of('parse_statement');
    my $else_fixes = $self->maybe(
        sub {
            $self->fail if $type eq 'unless';
            $self->expect('else');
            $self->sequence_of('parse_statement');
        }
    );
    $self->expect('end');
    my $cond = $self->_build_fix($name, 'Catmandu::Fix::Condition', $args);
    if ($type eq 'if') {
        $cond->pass_fixes($fixes);
        $cond->fail_fixes($else_fixes) if $else_fixes;
    }
    else {
        $cond->fail_fixes($fixes);
    }
    $cond;
}

sub parse_filter {
    my ($self) = @_;
    my $type  = $self->token_kw('select', 'reject');
    my $name  = $self->parse_name;
    my $args  = $self->parse_arguments;
    my $cond  = $self->_build_fix($name, 'Catmandu::Fix::Condition', $args);
    my $fixes = [require_package('Catmandu::Fix::reject')->new];
    if ($type eq 'select') {
        $cond->fail_fixes($fixes);
    }
    else {
        $cond->pass_fixes($fixes);
    }
    $cond;
}

sub parse_bind {
    my ($self) = @_;
    my $type  = $self->token_kw('do', 'doset');
    my $name  = $self->parse_name;
    my $args  = $self->parse_arguments;
    my $fixes = $self->sequence_of('parse_statement');
    $self->expect('end');
    my $bind = $self->_build_fix($name, 'Catmandu::Fix::Bind', $args);
    $bind->return($type eq 'doset');
    $bind->fixes($fixes);
    $bind;
}

sub parse_fix {
    my ($self) = @_;
    my $name   = $self->parse_name;
    my $args   = $self->parse_arguments;
    $self->_build_fix($name, 'Catmandu::Fix', $args);
}

sub parse_name {
    my ($self) = @_;
    $self->generic_token(name => qr/[a-z][_\da-zA-Z]*/);
}

sub parse_arguments {
    my ($self) = @_;
    $self->expect('(');
    my $args = $self->list_of(qr/[,:]|=>/, 'parse_value');
    $self->expect(')');
    $args;
}

sub parse_value {
    my ($self) = @_;
    $self->any_of(
        'parse_double_quoted_string',
        'parse_single_quoted_string',
        'parse_bare_string',
    );
}

sub parse_bare_string {
    my ($self) = @_;
    $self->generic_token(bare_string => qr/[^\s\\,;:=>()"']+/);
}

sub parse_single_quoted_string {
    my ($self) = @_;

    my $str = $self->generic_token(string => qr/'(?:[^']|\\')*'/);
    $str = substr($str, 1, length($str) - 2);

    $str =~ s{\\'}{'}gxms;

    $str;
}

sub parse_double_quoted_string {
    my ($self) = @_;

    my $str = $self->generic_token(string => qr/"(?:[^"]|\\")*"/);
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

sub _build_fix {
    my ($self, $name, $ns, $args) = @_;
    my $pkg;
    try {
        $pkg = require_package($name, $ns);
    }
    catch_case [
        'Catmandu::NoSuchPackage' => sub {
            Catmandu::NoSuchFixPackage->throw(
                message      => "No such fix package: $name",
                package_name => $_->package_name,
                fix_name     => $name,
            );
        },
    ];
    try {
        $pkg->new(@$args);
    }
    catch {
        $_->throw if is_instance($_, 'Catmandu::Error');
        Catmandu::BadFixArg->throw(
            message      => $_,
            package_name => $pkg,
            fix_name     => $name,
        );
    };
}

1;

__END__

=pod

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

Reads a string and returns a blessed object with parsed
Catmandu::Fixes. Throws an Catmandu::ParseError on failure.

=head1 SEE ALSO

L<Catmandu::Fix>

Or consult the webpages below for more information on the Catmandu::Fix language

http://librecat.org/Catmandu/#fixes
http://librecat.org/Catmandu/#fix-language

=cut
