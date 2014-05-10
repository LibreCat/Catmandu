package Catmandu::Fix::Bind::benchmark;

use Moo;
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);

with 'Catmandu::Fix::Bind';

has output => (is => 'ro' , required => 1);
has stats  => (is => 'lazy');

sub _build_stats {
	+{};
}

sub bind {
   my ($self,$data,$code,$name) = @_;
   $name = '<undef>' unless defined $name;
   my $t0 = [gettimeofday];
   $data = $code->($data);
   my $elapsed = tv_interval ( $t0 );

   $self->stats->{$name}->{count}   += 1;
   $self->stats->{$name}->{elapsed} += $elapsed;

   $data;
}

sub DESTROY {
	my ($self) = @_;
	local(*OUT);
	open (OUT, '>' , $self->output) || return undef;

	printf OUT "%-8.8s\t%-40.40s\t%-8.8s\t%-8.8s\n"
					, 'elapsed'
					, 'command'
					, 'calls'
					, 'sec/command';
	printf OUT "-" x 100 . "\n";

	for my $key (sort { $self->stats->{$b}->{elapsed} cmp $self->stats->{$a}->{elapsed} } keys %{$self->stats} ) {
		my $speed = $self->stats->{$key}->{elapsed} / $self->stats->{$key}->{count};
		printf OUT "%f\t%-40.40s\t%d times\t%f secs/command\n" 
					, $self->stats->{$key}->{elapsed}
					, $key 
					, $self->stats->{$key}->{count}
					, $speed;
	}

	printf OUT "\n\n";
	close (OUT);
}

1;