package Catmandu::Fix::Loader;

use Catmandu::Sane;
use Catmandu::Util qw(:is require_package read_file);

my $fixes;

sub load_fixes {
    $fixes = [];
    for my $fix (@{$_[0]}) {
        if (is_able($fix, 'fix')) {
            push @$fixes, $fix;
        } elsif (is_string($fix)) {
            if (-r $fix) {
                $fix = read_file($fix);
            }
            eval "package Catmandu::Fix::Loader::Env;$fix;1" or confess $@;
        }
    }
    $fixes;
}

sub add_fix {
    my ($fix, @args) = @_;
    $fix = require_package($fix, 'Catmandu::Fix');
    push @$fixes, $fix->new(@args);
}

package Catmandu::Fix::Loader::Env;

use strict;
use warnings;

sub AUTOLOAD {
    my ($fix) = our $AUTOLOAD =~ /::(\w+)$/;

    my $sub = sub { Catmandu::Fix::Loader::add_fix($fix, @_); return };

    { no strict 'refs'; *$AUTOLOAD = $sub };

    $sub->(@_);
}

sub DESTROY {}

package Catmandu::Fix;

use Catmandu::Sane;
use Catmandu::Util qw(:is :check);
use Moo;

has fixes => (
    is => 'ro',
    required => 1,
    coerce => sub {
        Catmandu::Fix::Loader::load_fixes(check_array_ref($_[0]));
    },
);

sub fix {
    my ($self, $data) = @_;

    my $fixes = $self->fixes;

    if (is_hash_ref($data)) {
        for my $fix (@$fixes) {
            $data = $fix->fix($data);
        }
        return $data;
    }

    if (is_array_ref($data)) {
        return [map {
            my $d = $_;
            $d = $_->fix($d) for @$fixes;
            $d;
        } @$data];
    }

    if (is_code_ref($data)) {
        return sub {
            my $d = $data->();
            defined($d) || return;
            $d = $_->fix($d) for @$fixes;
            $d;
        };
    }

    if (is_invocant($data)) {
        return $data->map(sub {
            my $d = $_[0];
            $d = $_->fix($d) for @$fixes;
            $d;
        });
    }

    return;
}

=head1 NAME

Catmandu::Fix - a Catmandu class used for data crunching

=head1 SYNOPSIS

    use Catmandu::Fix;

    my $fixer = Catmandu::Fix->new(fixes => ['upcase("job")','remove_field("test")']);

    or 

    my $fixer = Catmandu::Fix->new(fixes => ['fix_file.txt']);

    my $arr  = $fixer->fix([ ... ]);
    my $hash = $fixer->fix({ ... });
  
    my $it = Catmandu::Importer::YAML(file => '...');
    $fixer->fix($it)->each(sub {
	...
    });

=head1 DESCRIPTION

Catmandu::Fix-es can be use for easy data manipulation by non programmers. Using a
small Perl DSL language end-users can use Fix routines to manipulate data objects.
A plain text file of fixes can be created to specify all the routines needed to
tranform the data into the desired format.

=head1 PATHS

All the Fix routines in Catmandu::Fix use a TT2 type reference to point to values
in a Perl Hash. E.g. 'foo.2.bar' is a key 'bar' which is the 3-rd value of the 
key 'foo'.

A special case is when you want to point to all items in an array. In this case 
the wildcard '*' can be used. E.g. 'foo.*' points to all the items in the 'foo'
array.

For array values there are special wildcards available:

 * $append   - Add a new item at the end of an array
 * $prepend  - Add a new item at the start of an array
 * $first    - Syntactic sugar for index '0' (the head of the array)
 * $last     - Syntactic sugar for index '-1' (the tail of the array)

E.g.

 # Create { mods => { titleInfo => [ { 'title' => 'a title' }] } };
 add_field('mods.titleInfo.$append.title', 'a title');

 # Create { mods => { titleInfo => [ { 'title' => 'a title' } , { 'title' => 'another title' }] } };
 add_field('mods.titleInfo.$append.title', 'another title');

 # Create { mods => { titleInfo => [ { 'title' => 'foo' } , { 'title' => 'another title' }] } };
 add_field('mods.titleInfo.$first.title', 'foo');

 # Create { mods => { titleInfo => [ { 'title' => 'foo' } , { 'title' => 'bar' }] } };
 add_field('mods.titleInfo.$last.title', 'bar');

=head1 METHODS

=head2 new(fixes => [ FIX , ...])

Create a new Catmandu::Fix which will execute every FIX into a consecutive order. A
FIX can be the name of a Catmandu::Fix::* routine or the path to a plain text file
containing all the fixes to be executed.

=head2 fix(HASH)

Execute all the fixes on a HASH. Returns the fixed HASH.

=head2 fix(ARRAY)

Execute all the fixes on every element in the ARRAY. Returns an ARRAY of fixes.

=head2 fix(Catmandu::Iterator)

Execute all the fixes on every item in an Catmandu::Iterator. Returns a (lazy) iterator
on all the fixes.

=head2 fix(sub {})

Executes all the fixes on a generator function. Returns a new generator with fixed data.

=head1 SEE ALSO

L<Catmandu::Fix::add_field>

=cut

1;
