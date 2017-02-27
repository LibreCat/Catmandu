1;

=pod

=encoding utf8

=head1 Development Setup

The following guidelines describe how to set up a development environment for L<contribution|Catmandu::Help::Contribution> of code.

=head2 Set up a development environment

If you want to submit a patch for Catmandu, you need git and very likely also `milla` (L<Dist::Milla>). We also recommend L<perlbrew|https://perlbrew.pl/> (see below) to test and develop Catmandu on a recent version of perl. We also suggest L<App::cpanminus>) to quickly and comfortably install perl modules under I<perlbrew>.

In the following sections we provide tips for the installation of some of these tools together with L<Catmandu>. Please also see the documentation that comes with these tools for more info.

=head3 Perlbrew tips (Optional)

Install I<perlbrew> for example with 
    
    cpanm App::perlbrew

Check which perls are available

    perlbrew available

At the time of writing it looks like this

    perl-5.18.0
    perl-5.16.3
    perl-5.14.4
    perl-5.12.5
    perl-5.10.1
    perl-5.8.9
    perl-5.6.2
    perl5.005_04
    perl5.004_05
    perl5.003_07

Then go on and install a version inside Perlbrew. I recommend you give a name
to the installation (`--as` option), as well as compiling without the tests
(`--n` option) to speed it up.

    perlbrew install -n perl-5.16.3 --as catmandu_dev -j 3

Wait a while, and it should be done. Switch to your new Perl with:

    perlbrew switch catmandu_dev

Now you are using the fresh Perl, you can check it with:

    which perl

Install cpanm on your brewed version of perl:

    perlbrew install-cpanm


=head3 Get Catmandu sources

Get the Catmandu sources from github (for a more complete git workflow see 
below):

Clone your fork to have a local copy using the following command:

    $ git clone git@github.com:LibreCat/Catmandu.git

The installation is then straight forward:

    $ cd Catmandu
    $ perl Build.PL
    $ ./Build
    $ ./Build test
    $ ./Build install

You can now start with hacking Catmandu and L<patch submission|Catmandu::Help::Patch_Submission>!