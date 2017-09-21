package Catmandu::Fix::Parser;

use Catmandu::Sane;

our $VERSION = '1.0605';

use Catmandu::Util
    qw(check_value is_array_ref is_instance is_able require_package);
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
    my $statement = $self->any_of(
        'parse_filter', 'parse_if', 'parse_unless', 'parse_bind',
        'parse_fix',
    );

    # support deprecated separator
    $self->maybe_expect(';');
    $statement;
}

sub parse_filter {
    my ($self) = @_;
    my $type = $self->token_kw('select', 'reject');
    my $name = $self->parse_name;
    my $args = $self->parse_arguments;

    # support deprecated separator
    $self->maybe_expect(';');
    $self->_build_condition(
        $name, $args,
        $type eq 'reject',
        require_package('Catmandu::Fix::reject')->new
    );
}

sub parse_if {
    my ($self) = @_;
    my $type   = $self->token_kw('if');
    my $name   = $self->parse_name;
    my $args   = $self->parse_arguments;

    # support deprecated separator
    $self->maybe_expect(';');
    my $cond
        = $self->_build_condition($name, $args, 1, $self->parse_statements);
    my $elsif_conditions = $self->sequence_of(
        sub {
            $self->token_kw('elsif');
            my $name = $self->parse_name;
            my $args = $self->parse_arguments;

            # support deprecated separator
            $self->maybe_expect(';');
            $self->_build_condition($name, $args, 1, $self->parse_statements);
        }
    );
    my $else_fixes = $self->maybe(
        sub {
            $self->expect('else');
            $self->parse_statements;
        }
    );
    $self->expect('end');

    # support deprecated separator
    $self->maybe_expect(';');

    my $last_cond = $cond;

    if ($elsif_conditions) {
        for my $c (@$elsif_conditions) {
            $last_cond->fail_fixes([$c]);
            $last_cond = $c;
        }
    }

    if ($else_fixes) {
        $last_cond->fail_fixes($else_fixes);
    }

    $cond;
}

sub parse_unless {
    my ($self) = @_;
    my $type   = $self->token_kw('unless');
    my $name   = $self->parse_name;
    my $args   = $self->parse_arguments;

    # support deprecated separator
    $self->maybe_expect(';');
    my $cond
        = $self->_build_condition($name, $args, 0, $self->parse_statements);
    $self->expect('end');

    # support deprecated separator
    $self->maybe_expect(';');
    $cond;
}

sub parse_bind {
    my ($self) = @_;
    my $type = $self->token_kw('bind', 'do', 'doset');
    my $name = $self->parse_name;
    my $args = $self->parse_arguments;

    # support deprecated separator
    $self->maybe_expect(';');
    my $bind = $self->_build_bind($name, $args, $type eq 'doset',
        $self->parse_statements);
    $self->expect('end');

    # support deprecated separator
    $self->maybe_expect(';');
    $bind;
}

sub parse_fix {
    my ($self)   = @_;
    my $lft_name = $self->parse_name;
    my $lft_args = $self->parse_arguments;
    my $bool     = $self->maybe(
        sub {
            $self->any_of(
                sub {$self->expect(qr/and|&&/);  1},
                sub {$self->expect(qr/or|\|\|/); 0},
            );
        }
    );

    my $fix;

    if (defined $bool) {
        $self->commit;
        my $rgt_name = $self->parse_name;
        my $rgt_args = $self->parse_arguments;
        $fix = $self->_build_condition($lft_name, $lft_args, $bool,
            $self->_build_fix($rgt_name, $rgt_args));
    }
    else {
        $fix = $self->_build_fix($lft_name, $lft_args);
    }

    # support deprecated separator
    $self->maybe_expect(';');

    $fix;
}

sub parse_name {
    my ($self) = @_;
    $self->generic_token(name => qr/[a-z][_0-9a-zA-Z]*/);
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
    $self->any_of('parse_double_quoted_string', 'parse_single_quoted_string',
        'parse_bare_string',);
}

sub parse_bare_string {
    my ($self) = @_;
    $self->generic_token(bare_string => qr/[^\s\\,;:=>()"']+/);
}

sub parse_single_quoted_string {
    my ($self) = @_;

    my $str = $self->generic_token(string => qr/'(?:\\?+.)*?'/);
    $str = substr($str, 1, length($str) - 2);

    $str =~ s{\\'}{'}gxms;

    $str;
}

sub parse_double_quoted_string {
    my ($self) = @_;

    my $str = $self->generic_token(string => qr/"(?:\\?+.)*?"/);
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

sub _build_condition {
    my ($self, $name, $args, $pass, $fixes) = @_;
    $fixes = [$fixes] if !is_array_ref($fixes);
    my $cond = $self->_build_fix_ns($name, 'Catmandu::Fix::Condition', $args);
    if ($pass) {
        $cond->pass_fixes($fixes);
    }
    else {
        $cond->fail_fixes($fixes);
    }
    $cond;
}

sub _build_bind {
    my ($self, $name, $args, $return, $fixes) = @_;
    $fixes = [$fixes] if !is_array_ref($fixes);
    my $bind = $self->_build_fix_ns($name, 'Catmandu::Fix::Bind', $args);
    $bind->__return__($return);
    $bind->__fixes__($fixes);
    $bind;
}

sub _build_fix {
    my ($self, $name, $args) = @_;
    $self->_build_fix_ns($name, 'Catmandu::Fix', $args);
}

sub _build_fix_ns {
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
