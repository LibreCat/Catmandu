1;

=pod

=encoding utf8

=head1 Installation

To get Catmandu running on your system you need a Perl environment and to download and install at least the L<Catmandu> module from CPAN. Additional modules add support for more input and output formats, databases, and processing options.

=head2 Install Perl and CPAN client

We recommend to setup a local Perl development environment using L<plenv|https://github.com/tokuhirom/plenv> or L<perlbrew|https://perlbrew.pl/>.

For the installation of L<CPAN|https://metacpan.org/> modules use L<App::cpanminus>:

    $ cpan App::cpanminus
    # or
    $ curl -L http://cpanmin.us | perl - App::cpanminus

=head2 Catmandu

For a minimal L<Catmandu> installation run:

    $ cpanm Catmandu

You probably want to install more Catmandu tools like L<Catmandu::OAI>, L<Catmandu::MARC>, L<Catmandu::RDF>, L<Catmandu::SRU>, L<Catmandu::Store::MongoDB> and/or L<Catmandu::XLS>:

    $ cpanm Catmandu::MARC
    $ cpanm Catmandu::OAI
    $ cpanm Catmandu::RDF
    $ cpanm Catmandu::SRU
    $ cpanm Catmandu::Store::MongoDB
    $ cpanm Catmandu::XLS

To make full usage of the capabilities of Catmandu, database and search engines such as MongoDB, Elasticsearch, Solr, Postgres, MySQL can be installed on the system with the corresponding Catmandu tools. How to install these database on your local system falls outside the scope of this documentation. Please consult the installation guide of the database product for more information. For more information on the available Catmandu packages consult our L<Distributions|http://librecat.org/distributions.html> list.

Here are some Catmandu installation hints for various platforms.

=head2 Debian

Several Catmandu packages are officially included in Debian. The L<Debian|https://debian.org> project offers a list of L<currently available packages|https://packages.debian.org/libcatmandu>.

You can install all packages officially included in Debian:

    $ sudo apt-get update
    $ sudo apt-get install libcatmandu*-perl

Alternatively, you can build newest Catmandu and dependencies from source:


    $ sudo apt-get update
    $ sudo apt-get install cpanminus build-essential libexpat1-dev libssl-dev libxml2-dev libxslt1-dev libgdbm-dev libmodule-install-perl
    $ cpanm Catmandu

Alternatively, you can build newest Catmandu as unofficial packages, using most possible official packages:

    $ sudo apt update
    $ sudo apt install dh-make-perl liblocal-lib-perl apt-file
    $ sudo apt-file update
    $ sudo apt install libtest-fatal-perl libmodule-build-tiny-perl libmoo-perl libmodule-pluggable-perl libcapture-tiny-perl libclass-load-perl libgetopt-long-descriptive-perl libio-tiecombine-perl libstring-rewriteprefix-perl libio-handle-util-perl
    $ cpan2deb --vcs '' MooX::Aliases
    $ cpan2deb --vcs '' Log::Any
    $ cpan2deb --vcs '' App::Cmd
    $ cpan2deb --vcs '' LaTeX::ToUnicode
    $ cpan2deb --vcs '' PICA::Data
    $ cpan2deb --vcs '' LV
    $ cpan2deb --vcs '' MODS::Record
    $ sudo dpkg -i lib*-perl_*.deb
    $ cpan2deb --vcs '' BibTeX::Parser
    $ sudo dpkg -i libbibtex-parser-perl_*.deb
    $ sudo apt install libexporter-tiny-perl
    $ cpan2deb --vcs '' JSON::Path
    $ sudo dpkg -i libjson-path-perl_*.deb
    $ cpan2deb --vcs '' JSON::Hyper
    $ sudo dpkg -i libjson-hyper-perl_*.deb
    $ sudo apt install libhttp-link-parser-perl libautovivification-perl libmatch-simple-perl
    $ cpan2deb --vcs '' JSON::Schema
    $ sudo dpkg -i libjson-schema-perl_*.deb
    $ sudo apt install libjson-xs-perl libtest-exception-perl libtest-deep-perl libfile-slurp-tiny-perl liburi-template-perl libtry-tiny-byclass-perl libdata-util-perl libdata-compare-perl libhash-merge-simple-perl libthrowable-perl libclone-perl libdata-uuid-perl libmarpa-r2-perl libconfig-onion-perl libmodule-info-perl libtext-csv-perl libcgi-expand-perl
    $ dh-make-perl --vcs '' --cpan Catmandu
    $ perl -i -pe 's/libossp-uuid-perl[^,\n]*/libdata-uuid-perl/g' libcatmandu-perl/debian/control
    $ ( cd libcatmandu-perl && dpkg-buildpackage -b -us -uc -d )
    $ sudo dpkg -i libcatmandu-perl_*.deb
    $ dh-make-perl --vcs '' --cpan Catmandu::Twitter
    $ perl -i -pe 's/liburi-perl\K[^,\n]*//g' libcatmandu-twitter-perl/debian/control
    $ ( cd libcatmandu-twitter-perl && dpkg-buildpackage -b -us -uc -d )
    $ sudo apt install libchi-perl libnet-ldap-perl libdatetime-format-strptime-perl libxml-libxslt-perl libxml-struct-perl libnet-twitter-perl libxml-parser-perl libspreadsheet-xlsx-perl libexcel-writer-xlsx-perl libdevel-repl-perl libio-pty-easy-perl
    $ cpan2deb --recursive --vcs '' Task::Catmandu
    $ sudo apt install 'libcatmandu-*'
    $ sudo dpkg -i libcatmandu-twitter-perl_*.deb
    $ sudo dpkg -i ~/.cpan/build/libcatmandu-*-perl_*.deb

=head2 Ubuntu Server

    $ sudo apt-get install build-essential libmodule-install-perl perl-doc libgdbm-dev libwrap0-dev libssl-dev libyaz-dev zlib1g zlib1g-dev libxml2-dev libexpat1-dev libxslt1-dev
    $ cpanm Catmandu

=head2 CentOS 

=head3 Version 6.4

    $ yum groupinstall "Development Tools"
    $ yum install perl-CPAN perl-App-cpanminus perl-devel perl-ExtUtils-MakeMaker perl-YAML -y
    $ yum install gcc gdbm gdbm-devel openssl-devel tcp_wrappers-devel expat expat-devel libxml2 libxml2-devel libxslt libxslt-devel -y
    $ cpanm Catmandu

=head3 Version 7

    $ yum group install "Development Tools"
    $ yum install perl-devel perl-YAML perl-CPAN perl-App-cpanminus -y
    $ yum install openssl-devel tcp_wrappers-devel expat expat-devel libxml2 libxml2-devel libxslt libxslt-devel -y
    $ cpanm Catmandu

=head2 openSUSE

    $ sudo zypper install --type pattern devel_basis
    $ sudo zypper install libxml2-devel libxslt-devel
    $ cpanm Catmandu

=head2 OpenBSD 53

    $ cpanm Catmandu

=head2 OSX

    $ brew install libxml++ libxml2 xml2 libxslt
    # Install plenv from https://github.com/tokuhirom/plenv
    $ git clone https://github.com/tokuhirom/plenv.git ~/.plenv
    $ echo 'export PATH="$HOME/.plenv/bin:$PATH"' >> ~/.bash_profile
    $ echo 'eval "$(plenv init -)"' >> ~/.bash_profile
    $ exec $SHELL -l
    $ git clone https://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/
    # Install a modern Perl
    $ plenv install 5.22.0
    $ plenv rehash
    $ brew install cpanm
    # Install catmandu
    $ cpanm Catmandu
    $ plenv rehash

=head2 Windows 

We recommend to use L<Strawberry Perl|http://strawberryperl.com/> on Windows systems. After installation just run the follwing command from the I<cmd> shell:

    $ cpanm Catmandu

=head2 Raspbian GNU/Linux 7 on the Raspberry Pi (armhf)

Since Raspbian is based on Debian stable, you could follow the L<instructions|/Debian> there. Unfortunately, you will run into timeouts, so it is advisable to install some prerequisites via apt-get first:

    $ sudo apt-get install libboolean-perl libdevel-repl-perl libnet-twitter-perl 
    $ sudo apt-get install libxml-easy-perl libxslt1-dev libgdbm-dev

=head2 Windows, Mac OSX, Linux 

A L<docker image of Catmandu|https://registry.hub.docker.com/u/librecat/catmandu/> is build with each release. After L<installation of docker|https://docs.docker.com/installation/#installation> get and use the Catmandu image like this:

    # Upgrade to the latest version
    $ docker pull librecat/catmandu

    # Run the docker command
    $ docker run -it librecat/catmandu