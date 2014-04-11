package Catmandu::Fix::Parser;

use Catmandu::Sane;
use Catmandu::Util qw(is_array_ref check_string require_package read_file);
use Catmandu::Fix::Filter;
use Moo;

sub _build_fix_instance {
    my ($pkg, $ns, $args) = @_;
    my $class = require_package($pkg, $ns);
    $class->new(map {
        if (exists $_->{qq_string})  {
            $_->{qq_string};
        } elsif (exists $_->{q_string}) {
            $_->{q_string};
        } elsif (exists $_->{string}) {
            $_->{string};
        } else {
            $_->{int};
        }
    } @$args);
}

sub _parser {
    state $parser = do {
        use Regexp::Grammars;
        qr/
            <expr>

            <rule: expr>         <if_block>
                                 (?{ my $fix = $MATCH{if_block}{fix};
                                     my $instance = _build_fix_instance($fix->{name}, 'Catmandu::Fix::Condition', $fix->{args} || []);
                                     if ($MATCH{if_block}{expr}) {
                                         push @{$instance->fixes},
                                            map { $_->{instance} } @{$MATCH{if_block}{expr}};
                                     }
                                     if ($MATCH{if_block}{else_block} && $MATCH{if_block}{else_block}{expr}) {
                                         push @{$instance->else_fixes},
                                            map { $_->{instance} } @{$MATCH{if_block}{else_block}{expr}};
                                     }
                                     $MATCH{instance} = $instance;
                                 })
                                 |
                                 <unless_block>
                                 (?{ my $fix = $MATCH{unless_block}{fix};
                                     my $instance = _build_fix_instance($fix->{name}, 'Catmandu::Fix::Condition', $fix->{args} || []);
                                     if ($MATCH{unless_block}{expr}) {
                                         push @{$instance->else_fixes},
                                            map { $_->{instance} } @{$MATCH{unless_block}{expr}};
                                     }
                                     $MATCH{instance} = $instance;
                                 })
                                 |
                                 <select>
                                 (?{ my $fix = $MATCH{select}{fix};
                                     my $instance = _build_fix_instance($fix->{name}, 'Catmandu::Fix::Condition', $fix->{args} || []);
                                     push @{$instance->else_fixes}, Catmandu::Fix::Filter->new;
                                     $MATCH{instance} = $instance;
                                 })
                                 |
                                 <reject>
                                 (?{ my $fix = $MATCH{reject}{fix};
                                     my $instance = _build_fix_instance($fix->{name}, 'Catmandu::Fix::Condition', $fix->{args} || []);
                                     push @{$instance->fixes}, Catmandu::Fix::Filter->new;
                                     $MATCH{instance} = $instance;
                                 })
                                 |
                                 <fix>
                                 (?{ my $fix = $MATCH{fix};
                                     my $instance = _build_fix_instance($fix->{name}, 'Catmandu::Fix', $fix->{args} || []);
                                     $MATCH{instance} = $instance;
                                 })

            <rule: if_block>     if <fix> <[expr]>* <else_block>? end
                                 |
                                 if_<fix> <[expr]>* end \( \)

            <rule: else_block>   else <[expr]>*

            <rule: unless_block> unless <fix> <[expr]>* end
                                 |
                                 unless_<fix> <[expr]>* end \( \)

            <rule: select>       select \( <fix> \)
            <rule: reject>       reject \( <fix> \)

            <rule: fix>          <name> \( \)
                                 |
                                 <name> \( <args> \)

            <rule: args>         <[arg]>+ % <_sep>
                                 <MATCH= (?{ $MATCH{arg} })>

            <rule: arg>          <int>
                                 |
                                 <qq_string>
                                 |
                                 <q_string>
                                 |
                                 <string>
                                 |
                                 <fatal: Expected string or int>

            <token: keyword>     if|unless|end|select|reject

            <token: name>        <!keyword>
                                 [a-z][a-z0-9_-]*

            <token: int>         (-?\d+)
                                 <MATCH= (?{ eval $CAPTURE })>

            <token: qq_string>   "((?:[^\\"]|\\.)*)"
                                 <MATCH= (?{ $CAPTURE })>

            <token: q_string>    '((?:[^\\']|\\.)*)'
                                 <MATCH= (?{ $CAPTURE })>

            <token: string>      <!keyword>
                                 [^\s,;:=>\(\)"']+

            <token: _sep>        (?:\s|,|;|:|=>)+

            <token: ws>          (?:<_sep>)*
        /xms;
    };
}

sub parse {
    my ($self, $source) = @_;

    check_string($source);

    if ($source !~ /\(/) {
        $source = read_file($source);
    }

    $source =~ $self->_parser || do {
        my @err = @!;
        Catmandu::BadArg->throw(join("\n", "can't parse fix(es):", @err));
    };

    if (my $expr = $/{expr}) {
        if (is_array_ref($expr)) {
            [ map { $_->{instance} } @$expr ];
        } else {
            [ $expr->{instance} ];
        }
    } else {
        [];
    }
}

1;

