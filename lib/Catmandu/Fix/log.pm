package Catmandu::Fix::log;

use Catmandu::Sane;

our $VERSION = '1.0002_02';

use Moo;
use Catmandu;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Logger';

has message => (fix_arg => 1);
has level   => (fix_opt => 1);

sub fix {
    my ($self,$data) = @_;
    my $id    = $data->{_id} // '<undef>';
    my $level = $self->level // 'INFO';

    if ($level =~ /^(trace|debug|info|notice|warn|error|critical|alert|emergency)$/i) {
        my $lvl = lc $level;
        $self->log->$lvl(sprintf "%s : %s\n" , $id , $self->message);
    }

    $data;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::log - Log::Any logger as fix

=head1 SYNOPSIS

  log('test123')

  log('hello world' , level:DEBUG);

=head1 DESCRIPTION

This fix add debugging capabilities to fixes. To use it via the command line you need to add the
'-D' option to your script. E.g.

  echo '{}' | catmandu convert -D to YAML --fix 'log("help!", level:WARN)'

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
