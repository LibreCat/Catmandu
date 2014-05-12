package Catmandu::Fix::expand_date;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

my $DATE_REGEX = qr{
    ^([0-9]{4})
        (?: [:-] ([0-9]{1,2})
            (?: [:-] ([0-9]{1,2}) )?
        )?
}x;

has date_field => (fix_arg => 1, default => sub { 'date' });

sub fix {
    my ($self, $data) = @_;
    if (my $date = $data->{$self->date_field}) {
        if (my ($y, $m, $d) = $date =~ $DATE_REGEX) {
            $data->{year}  = $y;
            $data->{month} = 1*$m if $m;
            $data->{day}   = 1*$d if $d;
        }
    }
    $data;
}

1;

=head1 NAME

Catmandu::Fix::expand_date - expand a date field into year, month and date

=head1 SYNOPSIS

    # {date => "2001-09-11"}
    expand_date();
    # => {year => 2001, month => "9", day => "11", date => "2001-09-11"}

    # {datestamp => "2001:09"}
    expand_date('datestamp');
    # => {year => 2001, month => "9", datestamp => "2001:09"}

=head1 DESCRIPTION

The date field is expanded if it contains a year, optionally followed by
numeric month and day, each separated by C<-> or C<:>.


=cut
