package Catmandu::Fix::Null;

use Moose;

with 'Catmandu::Fix';

sub fix {
    my ($self, $obj, %args) = @_;

    $obj;
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

__END__

=head1 NAME

Catmandu::Fix::Null - trivial record fixer, does nothing

=head1 SYNOPSIS

    my $fixer = Catmandu::Fix::Null->new;

    # 'Fix' an object 
    my $omg_the_same_object = $fixer->fix($obj, %args);

=head2 $c->fix($obj, %args)

Fixes C<$obj>. C<$obj> can should a hashref. Args is a hash 
containing transformation options (scripts)

