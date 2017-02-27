1;

=pod

=encoding utf8

=head1 Contribution

This guide has been written to help anyone interested in contributing to the development of Catmandu. Please read this guide before contributing to Catmandu or related projects, to avoid wasted effort and maximizing the chances of your contributions being used.

=head2 Ways to contribute

There are many ways to contribute to the project: report bugs, write  documentation, submit patches or implement new features. Catmandu is a young yet active project and any kind of help is very much appreciated!

=head3 Publicity

You don't have to start by hacking the code, spreading the word is very valuable as well!

If you have a blog, just feel free to speak about Catmandu.

Of course, it doesn't have to be limited to blogs or Twitter. Feel free to spread the word in whatever way you consider fit and drop us a line on the Catmandu user mailing list noted below.

Also, if you're using and enjoying Catmandu, L<rating us on cpanratings.perl.org|http://cpanratings.perl.org/dist/Catmandu>, explaining what you like about Catmandu is another very valuable contribution that helps other new users find us!

=head3 Mailing list

Subscribing to the mailing list and providing assistance to new users is incredibly valuable.

=over

=item Mailing list: I<librecat-dev@lists.uni-bielefeld.de>

=item Subscribe or view archives here: L<https://lists.uni-bielefeld.de/mailman2/cgi/unibi/listinfo/librecat-dev>

=back

=head3 Documentation

We value documentation very much, but it's difficult to keep it up-to-date. If you find a typo or an error in the documentation please do let us know - ideally by submitting a patch (pull request) with your fix or suggestion (see L<Catmandu::Help::Patch_Submission>).

=head3 Code

To can contribute to Catmandu's core code or extend the functionality by new L<Importers|https://metacpan.org/search?q=Catmandu%3A%3AImporter>, L<Exporters|https://metacpan.org/search?q=Catmandu%3A%3AExporter>, L<Stores|https://metacpan.org/search?q=Catmandu%3A%3AStore>, L<Fix packages|https://metacpan.org/search?q=Catmandu%3A%3AFix>, L<Validators|https://metacpan.org/pod/Catmandu::Validator>, L<Binds|https://metacpan.org/search?q=Catmandu%3A%3AFix%3A%3ABind>, or L<Plugins|https://metacpan.org/search?q=Catmandu%3A%3APlugin>. Have a look at the list of L<missing modules|https://github.com/LibreCat/Catmandu/wiki/Missing-modules> for existing ideas and resources for new Catmandu modules. Feel also free to add new ideas and links there.

For more detailed guidelines, see:

=over

=item L<Catmandu::Help::Development_Setup> for how to set up a development environment

=item L<Catmandu::Help::Patch_Submission> for how to submit patches using the GitHub workflow

=item L<Catmandu::Help::Coding_Guidelines> for how to write readable code and documentation

=back

=head2 Quality Supervision and Reporting Bugs

We can measure our quality using the several platforms:

=over

=item L<CPAN Testers|http://www.cpantesters.org>

=item L<Travis CI|https://travis-ci.org/LibreCat/>

=item L<Coveralls|https://coveralls.io/github/LibreCat/>

A good way to help the project is to find a failing build log on the CPAN testers: L<CPAN Testers Matrix|http://www.cpantesters.org/distro/D/Catmandu.html>

If you find a failing test report or another kind of bug, feel free to report it as a GitHub issue: L<http://github.com/LibreCat/Catmandu/issues>. Please make sure the bug you're reporting does not yet exist.

=head2 Resources for Developers

=head3 Website

The official website is here: L<http://librecat.org/>. A Wordpress blog with hints is available at: L<https://librecatproject.wordpress.com/>

=head3 Mailing Lists

A mailing list is available here: I<librecat-dev@mail.librecat.org>

=head3 Repositories

The official repository is hosted on GitHub at L<http://github.com/LibreCat/Catmandu>.

Official developers have write access to this repository, contributors are
invited to fork the dev branch (!) and submit a pull request, as described 
at L<Patch Submission|/"Patch Submission">.

=head3 Core Maintainers

=over

=item L<Catmandu|https://metacpan.org/pod/Catmandu> - @nics
=item L<Catmandu::AWS|https://metacpan.org/pod/Catmandu::AWS> - @phochste
=item L<Catmandu::AlephX|https://metacpan.org/pod/Catmandu::AlephX> - @nicolasfranck
=item L<Catmandu::ArXiv|https://metacpan.org/pod/Catmandu::ArXiv> - @pietsch, @vpeil
=item L<Catmandu::Atom|https://metacpan.org/pod/Catmandu::Atom> - @phochste
=item L<Catmandu::BibTeX|https://metacpan.org/pod/Catmandu::BibTeX> - @pietsch, @vpeil
=item L<Catmandu::Cmd::fuse|https://metacpan.org/pod/Catmandu::Cmd::fuse> - @nics
=item L<Catmandu::Cmd::repl|https://metacpan.org/pod/Catmandu::Cmd::repl> - @pietsch
=item L<Catmandu::CrossRef|https://metacpan.org/pod/Catmandu::CrossRef> -@pietsch, @vpeil
=item L<Catmandu::DBI|https://metacpan.org/pod/Catmandu::DBI> - @nicolasfranck
=item L<Catmandu::DSpace|https://metacpan.org/pod/Catmandu::DSpace> - @nicolasfranck
=item L<Catmandu::EuropePMC|https://metacpan.org/pod/Catmandu::EuropePMC> - @vpeil
=item L<Catmandu::Exporter::ODS|https://metacpan.org/pod/Catmandu::Exporter::ODS> - @snorri
=item L<Catmandu::Exporter::RTF|https://metacpan.org/pod/Catmandu::Exporter::RTF> - @petrakohorst
=item L<Catmandu::Exporter::Template|https://metacpan.org/pod/Catmandu::Exporter::Template> - @vpeil
=item L<Catmandu::FedoraCommons|https://metacpan.org/pod/Catmandu::FedoraCommons> - @phochste
=item L<Catmandu::Fix::XML|https://metacpan.org/pod/Catmandu::Fix::XML> - @nichtich
=item L<Catmandu::Fix::cmd|https://metacpan.org/pod/Catmandu::Fix::cmd> - @nichtich
=item L<Catmandu::Importer::CPAN|https://metacpan.org/pod/Catmandu::Importer::CPAN> - @nichtich @phochste
=item L<Catmandu::Importer::Parltrack|https://metacpan.org/pod/Catmandu::Importer::Parltrack> - @jonas
=item L<Catmandu::Inspire|https://metacpan.org/pod/Catmandu::Inspire> - @vpeil
=item L<Catmandu::LDAP|https://metacpan.org/pod/Catmandu::LDAP> - @nics
=item L<Catmandu::MARC|https://metacpan.org/pod/Catmandu::MARC> - @phochste
=item L<Catmandu::MediaMosa|https://metacpan.org/pod/Catmandu::MediaMosa> - @nicolasfranck
=item L<Catmandu::OAI|https://metacpan.org/pod/Catmandu::OAI> - @pietsch, @phochste
=item L<Catmandu::ORCID|https://metacpan.org/pod/Catmandu::ORCID> - @pietsch
=item L<Catmandu::PLoS|https://metacpan.org/pod/Catmandu::PLoS> - @pietsch, @vpeil
=item L<Catmandu::Plack-REST|https://metacpan.org/pod/Catmandu::Plack-REST>  - @phochste
=item L<Catmandu::PubMed|https://metacpan.org/pod/Catmandu::PubMed> - @pietsch, @vpeil
=item L<Catmandu::RDF|https://metacpan.org/pod/Catmandu::RDF> - @nichtich
=item L<Catmandu::SRU|https://metacpan.org/pod/Catmandu::SRU> - @pietsch
=item L<Catmandu::Serializer::messagepack|https://metacpan.org/pod/Catmandu::Serializer::messagepack> - @nicolasfranck
=item L<Catmandu::Serializer::storable|https://metacpan.org/pod/Catmandu::Serializer::storable> - @nics
=item L<Catmandu::Store:CouchDB|https://metacpan.org/pod/Catmandu::Store:CouchDB> - @nics
=item L<Catmandu::Store::Elasticsearch|https://metacpan.org/pod/Catmandu::Store::Elasticsearch> - @nics
=item L<Catmandu::Store::Lucy|https://metacpan.org/pod/Catmandu::Store::Lucy> - @nics
=item L<Catmandu::Store::MongoDB|https://metacpan.org/pod/Catmandu::Store::MongoDB> - @nics
=item L<Catmandu::Store::Solr|https://metacpan.org/pod/Catmandu::Store::Solr> - @nicolasfranck , @nics
=item L<Catmandu::Twitter|https://metacpan.org/pod/Catmandu::Twitter> - @pietsch
=item L<Catmandu::XLS|https://metacpan.org/pod/Catmandu::XLS> - @jorol, @nics
=item L<Catmandu::Z3950|https://metacpan.org/pod/Catmandu::Z3950> - @pietsch
=item L<Dancer:Plugin::Auth::RBAC::Credentials:Catmandu|https://metacpan.org/pod/Dancer:Plugin::Auth::RBAC::Credentials:Catmandu> - @nicolasfranck
=item L<Dancer::Plugin::Catmandu::OAI|https://metacpan.org/pod/Dancer::Plugin::Catmandu::OAI> - @nicolasfranck
=item L<Dancer::Plugin::Catmandu::SRU|https://metacpan.org/pod/Dancer::Plugin::Catmandu::SRU> - @nics, phochste
=item L<Dancer::Session::Catmandu|https://metacpan.org/pod/Dancer::Session::Catmandu> - @nics
=item L<LibreCat::Sitemap|https://metacpan.org/pod/LibreCat::Sitemap> - @phochste
=item L<MODS::Record|https://metacpan.org/pod/MODS::Record> - @phochste
=item L<Plack::Session::Store::Catmandu|https://metacpan.org/pod/Plack::Session::Store::Catmandu> - @nics
=item L<Task::Catmandu|https://metacpan.org/pod/Task::Catmandu> - @nics
=item L<WWW::ORCID|https://metacpan.org/pod/WWW::ORCID> - @nics

=back