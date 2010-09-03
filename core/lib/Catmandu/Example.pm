package Catmandu::Example;

sub new {
  my $pkg = shift;
  return bless {} , $pkg;
}

sub ok {
  return 1;
}

sub fail {
  return 0;
}

sub throw {
  die "aargh";
}

1;

__END__

=head1 NAME

Catmandu::Example - [FILL IN THE PURPOSE]

=head1 SYNOPSIS

 [FILL IN EXAMPLE USAGE]

=head1 DESCRIPTION

 [FILL IN TEXTUAL DESCRIPTION OF THIS PACKAGE]

=head1 METHODS

=over 4

=item method1

[DOCUMENTATION]

=item method2

[DOCUMENTATION]

=back

=head1 AUTHORS

Read the AUTHORS.txt in the root of this package

=head1 LICENSE

Copyright 2010 Ghent University & Lund University

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
