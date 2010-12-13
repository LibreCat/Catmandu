package Catmandu::Dist;

use 5.010;
use Try::Tiny;
use Carp;
use File::ShareDir;
use Path::Class;
use namespace::clean;
use Sub::Exporter -setup => {
    exports => [qw(
        share_dir
    )],
};

sub share_dir {
    state $share_dir //= try {
        File::ShareDir::dist_dir('Catmandu');
    } catch {
        /failed to find share dir for dist/i or croak $_;
        file(__FILE__)->dir->parent->parent
            ->subdir('share')
            ->absolute->resolve->stringify;
    };
}

1;

