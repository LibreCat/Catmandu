#!perl

use Catmandu;
use Catmandu::CLI;
use Cwd ();

Catmandu->default_load_path(Cwd::getcwd);
Catmandu::CLI->run // exit(2);

=head1 NAME

ca - An alias for catamndu (LibreCat command line tools)

=cut
