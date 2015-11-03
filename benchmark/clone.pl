#!/usr/bin/env perl

BEGIN {
    use strict;
    use warnings;
    use FindBin;
    use File::Spec ();
    use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');
    use Catmandu ();
    use Benchmark qw(:all);
}

package NothingFix;

use strict;
use warnings;
use Moo;
use Clone qw(clone);

sub fix {
    $_[0];
}

package CloneFix;

use strict;
use warnings;
use Moo;
use Clone qw(clone);

sub fix {
    clone($_[0]);
}

package DataCloneFix;

use strict;
use warnings;
use Moo;
use Data::Clone qw(clone);

sub fix {
    clone($_[0]);
}

package main;

my $data = Catmandu->importer('JSON',
    file => File::Spec->catfile($FindBin::Bin, 'data.json'))->first;
my $nothing_fixer = Catmandu::Fix->new(fixes => [(NothingFix->new) x 1000]);
my $clone_fixer = Catmandu::Fix->new(fixes => [(CloneFix->new) x 1000]);
my $data_clone_fixer = Catmandu::Fix->new(fixes => [(DataCloneFix->new) x 1000]);

cmpthese(10000, {
        "nothing" => sub { $nothing_fixer->fix($data) },
        "Clone" => sub { $clone_fixer->fix($data) },
        "Data::Clone" => sub { $data_clone_fixer->fix($data) },
});

