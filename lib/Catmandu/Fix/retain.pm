package Catmandu::Fix::retain;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Moo;
use Catmandu::Util qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

has paths => (
    fix_arg => 'collect',
    default => sub {[]},
    coerce  => sub {
        [map {as_path($_)} @{$_[0]}];
    }
);
has getters_and_creators => (is => 'lazy');

sub _build_getters_and_creators {
    my ($self) = @_;
    [map {[$_->getter, $_->creator]} @{$self->paths}];
}

sub fix {
    my ($self, $data) = @_;
    my $tmp = {};
    for my $pair (@{$self->getters_and_creators}) {
        my $vals = $pair->[0]->($data);
        while (@$vals) {
            $pair->[1]->($tmp, shift @$vals);
        }
    }
    undef %$data;
    for my $key (keys %$tmp) {
        $data->{$key} = $tmp->{$key};
    }
    $data;
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
