package Catmandu::Cmd::compile;

use Catmandu::Sane;

our $VERSION = '1.06';

use parent 'Catmandu::Cmd';
use Catmandu;
use Data::Dumper;
use namespace::clean;

sub command_opt_spec {
    (
        ["var=s%",        ""],
        ["preprocess|pp", ""],
        ["fix|fix=s@", "", {hidden => 1}],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    unless (@$args == 1) {
        say STDERR "usage: $0 compile <FILE>|<FIX> [<FILE>|<FIX> [...]]\n";
        exit 1;
    }

    $opts->{fix} = $args;

    my $fixer    = $self->_build_fixer($opts);
    my $fixes    = $fixer->emit;
    my $captures = Dumper($fixer->_captures);

    $captures =~ s/^\$VAR1/\$_[1]/;

    print $captures;
    print $fixes;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::compile - compile a Fix into Perl (for debugging)

=head1 EXAMPLES

  catmandu compile <FILE>|<FIX> [<FILE>|<FIX> [...]]

  catmandu compile 'add_field(foo,bar.$append)' | perltidy -utf8 -npro -st -se

=cut
