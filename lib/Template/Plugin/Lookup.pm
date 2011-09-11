# indexes a list of hashes by it's id key in an inverse hash
#
# usage:
#   $departments = [
#          {
#              id => 'WE',
#              name => 'Faculty of Science',
#              children => [
#                  {
#                      id => 'WE01',
#                      name => 'Department of Mathematics',
#                  },
#              ],
#          },
#  ]
#
#  [% USE Lookup %]
#  [% lookup = Lookup.list(departments) %]
#  [% lookup.item('WE01').name %]
#
package Template::Plugin::Lookup;
use strict;
use warnings;
use parent qw(Template::Plugin);
use Hash::Util::FieldHash qw(fieldhash);

fieldhash my %memo;

sub new {
    my ($class, $context) = @_;
    bless {}, $class;
}

sub list {
    my ($self, $list) = @_;
    $memo{$list} ||= $self->index_list($list);
}

sub index_list {
    my ($self, $list, $index) = @_;
    $index ||= {};
    for my $item (@$list) {
        $index->{$item->{id}} = $item;
        if (my $children = $item->{children}) {
            $self->index_list($children, $index);
        }
    }
    $index;
}

1;
