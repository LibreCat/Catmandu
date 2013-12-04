package Catmandu::Fix::Parser;

use Catmandu::Sane;
use Catmandu::Util qw(:is require_package read_file);
use Moo;

sub parse {
    state $parser = do {
        use Regexp::Grammars;
        qr/
            <fixes>

            <rule: fixes>        <[expr]>*
                                 <MATCH= (?{ $MATCH{expr} })>

            <rule: expr>         <if_block>
                                 (?{ my $fix = $MATCH{if_block}{fix};
                                     my $args = $fix->{args} ||= [];
                                     my $class = require_package($fix->{name}, 'Catmandu::Fix::Condition');
                                     my $instance = $class->new(map {
                                         exists $_->{string} ? $_->{string} : $_->{int};
                                     } @$args);
                                     if ($MATCH{if_block}{fixes}) {
                                         push @{$instance->fixes},
                                            map { $_->{instance} } @{$MATCH{if_block}{fixes}};
                                     }
                                     if ($MATCH{if_block}{else_block} && $MATCH{if_block}{else_block}{fixes}) {
                                         push @{$instance->else_fixes},
                                            map { $_->{instance} } @{$MATCH{if_block}{else_block}{fixes}};
                                     }
                                     $MATCH{instance} = $instance;
                                 })
                                 |
                                 <unless_block>
                                 (?{ my $fix = $MATCH{unless_block}{fix};
                                     my $args = $fix->{args} ||= [];
                                     my $class = require_package($fix->{name}, 'Catmandu::Fix::Condition');
                                     my $instance = $class->new(map {
                                         exists $_->{string} ? $_->{string} : $_->{int};
                                     } @$args);
                                     if ($MATCH{unless_block}{fixes}) {
                                         push @{$instance->else_fixes},
                                            map { $_->{instance} } @{$MATCH{unless_block}{fixes}};
                                     }
                                     $MATCH{instance} = $instance;
                                 })
                                 |
                                 <fix>
                                 (?{ my $fix = $MATCH{fix};
                                     my $args = $fix->{args} ||= [];
                                     my $class = require_package($fix->{name}, 'Catmandu::Fix');
                                     my $instance = $class->new(map {
                                         exists $_->{string} ? $_->{string} : $_->{int};
                                     } @$args);
                                     $MATCH{instance} = $instance;
                                 })

            <rule: if_block>     if <fix> <fixes> <else_block>? end

            <rule: else_block>   else <fixes>

            <rule: unless_block> unless <fix> <fixes> end

            <rule: fix>          <name> \( \)
                                 |
                                 <name> \( <args> \)

            <rule: args>         <[arg]>+ % <_sep>
                                 <MATCH= (?{ $MATCH{arg} })>

            <rule: arg>          <string>
                                 |
                                 <int>
                                 |
                                 <fatal: Expected string or int>

            <token: name>        [a-z_][a-z0-9_]*

            <token: string>      "((?:[^\\"]|\\.)*)"
                                 <MATCH= (?{ $CAPTURE })>

            <token: int>         (-?\d+)
                                 <MATCH= (?{ eval $CAPTURE })>

            <token: _sep>        [\s,;]+

            <token: ws>          (?:<_sep>)*
        /xms;
    };

    my ($self, @sources) = @_;
    @sources = map { ref $_ ? @$_ : $_ } @sources;
    my $fixes = [];

    for my $source (@sources) {
        if (is_able($source, 'fix')) {
            push @$fixes, $source;
        } elsif (is_string($source)) {
            if ($source !~ /[\r\n\t\v\*]/ && -f $source) {
                $source = read_file($source);
            }
            $source =~ $parser || do {
                my @errors = @!;
                Catmandu::BadArg->throw(join("\n", "cannot parse fix:", @errors));
            };
            if (my $parsed = $/{fixes}) {
                use Data::Dumper::Concise;say Dumper($parsed);
                push @$fixes, map { $_->{instance} } @$parsed;
            }
        }
    }

    $fixes;
}

1;

