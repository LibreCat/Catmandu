package Catmandu::Fix::retain;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has paths => (fix_arg => 'collect', default => sub {[]},);

sub _build_fixer {
    my ($self)   = @_;
    my $paths    = [map {as_path($_)} @{$self->paths}];
    my $getters  = [map {$_->getter} @$paths];
    my $creators = [map {$_->creator} @$paths];

    sub {
        my $data = $_[0];
        my $temp = {};
        for (my $i = 0; $i < @$getters; $i++) {
            my $getter  = $getters->[$i];
            my $creator = $creators->[$i];
            my $values  = $getter->($data);
            while (@$values) {
                $creator->($temp, shift @$values);
            }
        }
        undef %$data;
        for my $key (keys %$temp) {
            $data->{$key} = $temp->{$key};
        }
        $data;
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::retain - delete everything except the paths given

=head1 SYNOPSIS

   # Keep the field _id , name , title
   retain(_id , name, title)

   # Delete everything except foo.bar 
   #   {bar => { x => 1} , foo => {bar => 1, y => 2}}
   # to
   #   {foo => {bar => 1}}
   retain(foo.bar)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
