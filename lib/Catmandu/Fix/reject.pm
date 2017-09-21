package Catmandu::Fix::reject;

use Catmandu::Sane;

our $VERSION = '1.0604';

use Moo;
use namespace::clean;

with 'Catmandu::Fix::Base';

sub emit {
    my ($self, $fixer) = @_;
    $fixer->emit_reject;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::reject - remove a record form the data

=head1 SYNOPSIS

  # Reject all items from from the output
  reject()

  # Reject all items with have an 'ignore_me' field
  reject exists(ignore_me)

  # Reject all items with have a 'ignore' field with value 'true'
  reject all_match(ignore,true)

  # Select all items 
  select()

  # Select only those items that have an 'include_me' field
  select exists(include_me)
 
  # Select only those items that have an 'include' field with value 'true'
  select all_match(include,true)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
