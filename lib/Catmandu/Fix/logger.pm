=head1 NAME

Catmandu::Fix::logger - Log::Any logger as fix

=head1 SYNOPSIS

  logger('test123');

  logger('hello world' , level => 'DEBUG');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
package Catmandu::Fix::logger;
use Moo;
use Catmandu;
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