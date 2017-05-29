1;

=pod

=encoding utf8

=head1 Fix language

Catmandu comes with a small domain specific language for manipulation of data
L<Items|Catmandu::Help::Items> called Fix. The Fix consists of

  * L<Paths|Catmandu::Help::Paths> to refer to particular parts of an item
  * L<Functions|Catmandu::Help::Functions> to manipulate (parts of) an item
  * L<Selectors|Catmandu::Help::Selectors> to manipulate which items end up in the end result
  * L<Conditionals|Catmandu::Help::Conditionals> to control when to apply which Fix functions
  * L<Binds|Catmandu::Help::Binds> to manipulate the execution of Fix functions
  * L<Comments|Catmandu::Help::Comments> to provide documentation in the Fix script
