package Catmandu::Fix::Condition;

use Catmandu::Sane;

our $VERSION = '1.0605';

use Moo::Role;
use namespace::clean;
use Catmandu::Fix::reject;

with 'Catmandu::Fix::Base';

has pass_fixes => (is => 'rw', default => sub {[]});
has fail_fixes => (is => 'rw', default => sub {[]});

sub import {
    my $target = caller;
    my ($fix, %opts) = @_;

    if (my $sym = $opts{as}) {
        my $sub = sub {
            my $data = shift;
            if ($opts{clone}) {
                $data = Clone::clone($data);
            }
            my $cond = $fix->new(@_);
            $cond->fail_fixes([Catmandu::Fix::reject->new]);
            !!$cond->fix($data);
        };
        no strict 'refs';
        *{"${target}::$sym"} = $sub;
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition - Role for all Catmandu::Fix conditionals

=head1 SYNOPSIS

	if <Catmandu::Fix::Condition instance>
		<pass_fixes>
	else
		<fail_fixes>
	end

=head1 DESCRIPTION 

All L<Catmandu::Fix> conditions need to implement Catmandu::Fix::Condition.
This subclass of L<Catmandu::Fix::Base> provides a list of fixes that need to
be executed when a conditional matches (pass_fixes) and conditional that need
to be executed when a conditional fails (fail_fixes).

Conditions can be used as inline fixes as well:

    use Catmandu::Fix::Condition::exists as => 'has_field';
    
    my $item = { foo => { bar => 1 } };

    has_field($item, 'foo.bar');    # true
    has_field($item, 'doz');        # false

=head1 EXAMPLES

Catmandu core comes with the following conditions:

=over

=item 

L<all_equal|Catmandu::Fix::Condition::all_equal>

=item 

L<all_match|Catmandu::Fix::Condition::all_match>

=item

L<any_equal|Catmandu::Fix::Condition::any_equal>

=item

L<any_match|Catmandu::Fix::Condition::any_match>

=item 

L<exists|Catmandu::Fix::Condition::exists>

=item 

L<greater_than|Catmandu::Fix::Condition::greater_than>

=item 

L<in|Catmandu::Fix::Condition::in>

=item

L<is_array|Catmandu::Fix::Condition::is_array>

=item

L<is_false|Catmandu::Fix::Condition::is_false>

=item

L<is_null|Catmandu::Fix::Condition::is_null>

=item

L<is_number|Catmandu::Fix::Condition::is_number>

=item

L<is_object|Catmandu::Fix::Condition::is_object>

=item

L<is_string|Catmandu::Fix::Condition::is_string>

=item

L<is_true|Catmandu::Fix::Condition::is_true>

=item 

L<less_than|Catmandu::Fix::Condition::less_than>

=back

=cut
