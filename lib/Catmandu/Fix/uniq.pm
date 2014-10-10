package Catmandu::Fix::uniq;
use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path  => (fix_arg => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;

    $fixer->emit_walk_path($fixer->var,$path,sub {

        my $var = shift;

        $fixer->emit_get_key($var, $key, sub {

            my $var = shift;
            my $seen = $fixer->generate_var();
            my $seen_undef = $fixer->generate_var();

            my $p = "";
            $p .= "my ${seen} = {};";
            $p .= "my ${seen_undef} = 0;";

            #use of undefined hash keys is not allowed in perl (a warning is written to stderr): 'use of uninitialized value in hash element'
            #that's why I do not use the function List::MoreUtils::uniq

            $p .= "${var} = [ grep { defined(\$_) ? ( !( ${seen}->{ \$_ }++ ) ) : ( ${seen_undef} ? 0 : ( ${seen_undef} = 1 ) ) } \@{ ${var} }  ] if is_array_ref(${var});";

            $p;

        });
    });

}

=head1 NAME

Catmandu::Fix::uniq - remove duplicates from a list

=head1 SYNOPSIS

   #["RE","RE"] becomes ["RE"]
   uniq('faculty');

=head1 AUTHOR

Nicolas Franck, C<< nicolas.franck at ugent.be >>

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
