package Catmandu::Fix::Condition;

=head1 NAME

Catmandu::Fix::Condition - Role for all Catmandu::Fix conditionals

=head1 SYNOPSIS

	if <Catmandu::Fix::Condition instance>
		<pass_fixes>
	else
		<fail_fixes>
	end

=head1 DESCRIPTION 

All Catmandu::Fix conditional need to implement Catmandu::Fix::Condition which provides
a list of fixes that need to be executed when a conditional matches (pass_fixes) and
conditional that need to be executed when a conditional fails (fail_fixes).

=head1 SEE ALSO

L<Catmandu::Fix>, 
L<Catmandu::Fix::Condition::all_match>, 
L<Catmandu::Fix::Condition::any_match>, 
L<Catmandu::Fix::Condition::exists>, 

=cut

use Catmandu::Sane;
use Moo::Role;

with 'Catmandu::Fix::Base';

has pass_fixes => (is => 'rw', default => sub { [] });
has fail_fixes => (is => 'rw', default => sub { [] });

1;
