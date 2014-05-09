package Catmandu::Fix::Bind::eval;

use Moo;
use Data::Dumper;
use Perl::Tidy;

with 'Catmandu::Fix::Bind';

sub bind {
	my ($self,$data,$code,$name,$perl) = @_;
	
	eval {
		$data = $code->($data);
	};
	if ($@) {
		warn "$name : failed : $@";
	}

	$data
}

1;