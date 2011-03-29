=== Installation ===

This example requires Dancer and Module::Pluggable to be installed.  All other
dependencies should already be satisfied by the normal Catmandu installation
process.

If you copy this example to another directory and do not already have the
Catmandu modules installed to a location in your @INC, you will need to
modify the "use lib" statement in lib/HepCat/Model/Catmandu.pm so that it
points to the location of your Catmandu modules.


=== Usage ===

To start the server:
./bin/app.pl

To access the application, once the server is running:
http://localhost:3000/

