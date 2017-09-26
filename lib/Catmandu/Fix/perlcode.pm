package Catmandu::Fix::perlcode;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

our %CACHE;

has file => (fix_arg => 1);

has code => (
    is      => 'lazy',
    builder => sub {
        my $file = $_[0]->file;
        $CACHE{$file} //= do $_[0]->file;
    }
);

sub emit {
    my ($self, $fixer) = @_;

    my $code   = $fixer->capture($self->code);
    my $var    = $fixer->var;
    my $reject = $fixer->capture({});

    "if (${code}->(${var},${reject}) == ${reject}) {"
        . $fixer->emit_reject . "}";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::perlcode - execute Perl code as fix function

=head1 DESCRIPTION

Use this fix in the L<Catmandu> fix language to make use of a Perl script:

    perlcode(myscript.pl)

The script (here C<myscript.pl>) must return a code reference:

    sub {
        my $data = shift;
        ...
        return $data;
    }

When not using the fix language this 

    my $fixer = Catmandu::Fix->new( fixes => [ do 'myscript.pl' ] );
    $fixer->fix( $item ); 

is roughly equivalent to:

    my $code = do 'myscript.pl';
    $item = $code->( $item )

All scripts are cached based on their filename, so using this fix multiple
times will only load each given script once.

The code reference gets passed a second value to reject selected items such as
possible with see L<Catmandu::Fix::reject>:

    sub {
        my ($data, $reject) = @_;
        return rejection_criteria($data) ? $reject : $data;
    }

To indicate the end processing, return C<undef>.

=head1 SEE ALSO

L<Catmandu::Fix::code>, L<Catmandu::Fix::cmd>

=cut
