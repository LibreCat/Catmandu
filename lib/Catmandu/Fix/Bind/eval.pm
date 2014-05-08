package Catmandu::Fix::Bind::eval;

use Moo;
use Data::Dumper;

with 'Catmandu::Fix::Bind';

sub bind {
	my ($self,$data,$code,$name,$perl) = @_;
	
	eval {
		$data = $code->($data);
	};
	if ($@) {
		warn "$name $perl";
		die "Fix: $name threw an error: $@";
	}

	$data
}

1;