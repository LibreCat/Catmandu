package Catmandu::Fix::split_date;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

my $DATE_REGEX = qr{
    ^([0-9]{4})
        (?: [:-] ([0-9]{1,2})
            (?: [:-] ([0-9]{1,2}) )?
        )?
}x;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;

    my $date_re = $fixer->capture($DATE_REGEX);
    my $perl = <<EOF;
if( is_string(${var}) && ${var} =~ ${date_re} ){
    ${var} = {};
    ${var}->{year} = \${1};
    ${var}->{month} = 1*\${2} if \${2};
    ${var}->{day} = 1*\${3} if \${3};
}
EOF

}

1;

=head1 NAME

Catmandu::Fix::split_date - split a date field into year, month and date

=head1 SYNOPSIS

    # {date => "2001-09-11"}
    expand_date('date')
    # => { date => { year => 2001, month => "9", day => "11" } }

    # { datestamp => "2001:09" }
    expand_date('datestamp')
    # => { datestamp => { year => 2001, month => "9" } }

=head1 DESCRIPTION

The date field is expanded if it contains a year, optionally followed by
numeric month and day, each separated by C<-> or C<:>.


=cut
