package Catmandu::Pluggable;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Moo::Role;
use namespace::clean;

sub plugin_namespace {'Catmandu::Plugin'}

sub with_plugins {
    my $class = shift;
    $class = ref $class || $class;
    my @plugins = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
    @plugins = split /,/, join ',', @plugins;
    @plugins || return $class;
    my $ns = $class->plugin_namespace;
    Moo::Role->create_class_with_roles(
        $class,
        map {
            my $pkg = $_;
            if ($pkg !~ s/^\+// && $pkg !~ /^$ns/) {
                $pkg = "${ns}::${pkg}";
            }
            $pkg;
        } @plugins
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Pluggable - A role for classes that need plugin capabilities

=head1 SYNOPSIS

    package My::Foo::Bar;

    use Role::Tiny;

    before foo => sub {
        print "Before foo!\n";
    };

    after foo => sub {
        print "After foo!\n";
    };

    sub extra {
        print "I can do extra too\n";
    }

    package My::Foo;

    use Moo;

    with 'Catmandu::Pluggable';

    sub plugin_namespace {
        'My::Foo';
    }

    sub foo {
        print "Foo!\n";
    }

    package main;

    my $x = My::Foo->with_plugins('Bar')->new;

    # prints:
    #  Before foo!
    #  Foo!
    #  After foo!
    $x->foo;

    # prints:
    #  I can do extra too
    $x->extra;

=head1 METHODS

=head2 plugin_namespace 

Returns the namespace where all plugins for your class can be found.

=head2 with_plugins(NAME)

=head2 with_plugins(NAME,NAME,...)

This class method returns a subclass of your class with all provided plugins NAME-s implemented.

=head1 SEE ALSO

L<Catmandu::Bag>,
L<Catmandu::Plugin::Datestamps>,
L<Catmandu::Plugin::Versioning>

=cut
