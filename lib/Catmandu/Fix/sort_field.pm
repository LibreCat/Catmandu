package Catmandu::Fix::sort_field;

use Catmandu::Sane;

our $VERSION = '1.2013';

use List::MoreUtils qw(uniq);
use Catmandu::Util::Path qw(as_path);
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path           => (fix_arg => 1);
has uniq           => (fix_opt => 1);
has reverse        => (fix_opt => 1);
has numeric        => (fix_opt => 1);
has undef_position => (fix_opt => 1, default => sub {'last'});

sub _build_fixer {
    my ($self)         = @_;
    my $uniq           = $self->uniq;
    my $reverse        = $self->reverse;
    my $numeric        = $self->numeric;
    my $undef_position = $self->undef_position;
    as_path($self->path)->updater(
        if_array_ref => sub {
            my $val = $_[0];

            #filter out undef
            my $undefs = [grep {!defined($_)} @$val];
            $val = [grep {defined($_)} @$val];

            #uniq
            if ($uniq) {
                $val = [uniq(@$val)];
            }

            #sort
            if ($reverse && $numeric) {
                $val = [sort {$b <=> $a} @$val];
            }
            elsif ($numeric) {
                $val = [sort {$a <=> $b} @$val];
            }
            elsif ($reverse) {
                $val = [sort {$b cmp $a} @$val];
            }
            else {
                $val = [sort {$a cmp $b} @$val];
            }

            #insert undef at the end
            if ($undef_position eq 'first') {
                if ($uniq) {
                    unshift @$val, undef if @$undefs;
                }
                else {
                    unshift @$val, @$undefs;
                }
            }
            elsif ($undef_position eq 'last') {
                if ($uniq) {
                    push @$val, undef if @$undefs;
                }
                else {
                    push @$val, @$undefs;
                }
            }

            $val;
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::sort_field - sort the values of an array

=head1 SYNOPSIS

   # e.g. tags => ["foo", "bar","bar"]
   sort_field(tags) # tags =>  ["bar","bar","foo"]
   sort_field(tags, uniq: 1) # tags =>  ["bar","foo"]
   sort_field(tags, uniq: 1, reverse: 1) # tags =>  ["foo","bar"]
   # e.g. nums => [ 100, 1 , 10]
   sort_field(nums, numeric: 1) # nums => [ 1, 10, 100]

   #push undefined values to the end of the list (default)
   #beware: reverse has no effect on this!
   sort_field(tags,undef_position: last)

   #push undefined values to the beginning of the list
   #beware: reverse has no effect on this!
   sort_field(tags,undef_position: first)

   #remove undefined values from the list
   sort_field(tags,undef_position: delete)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
