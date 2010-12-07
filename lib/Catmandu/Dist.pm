package Catmandu::Dist;

use 5.010;
use namespace::autoclean;
use Try::Tiny;
use Carp;
use File::ShareDir;
use Path::Class;

sub share {
    state $share //= try {
        File::ShareDir::dist_dir('Catmandu');
    } catch {
        when (/failed to find share dir for dist/i) {
            file(__FILE__)->dir->parent->parent->subdir('share')
                ->absolute->resolve->stringify;
        }
        default {
            croak $_;
        }
    };
}

1;

