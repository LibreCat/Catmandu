package Catmandu::Error;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Throwable::Error';

package Catmandu::BadVal;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::Error';

package Catmandu::BadArg;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::BadVal';

package Catmandu::NotImplemented;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::Error';

package Catmandu::NoSuchPackage;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::Error';

has package_name => (is => 'ro');

package Catmandu::FixParseError;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::Error';

has source => (is => 'ro');

package Catmandu::NoSuchFixPackage;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::NoSuchPackage';

has fix_name => (is => 'ro');
has source => (is => 'rw', writer => 'set_source');

package Catmandu::BadFixArg;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::BadArg';

has package_name => (is => 'ro');
has fix_name => (is => 'ro');
has source => (is => 'rw', writer => 'set_source');

package Catmandu::FixError;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::Error';

has data => (is => 'ro');
has fix => (is => 'ro');

=head1 NAME

Catmandu::Error - Catmandu error hierarchy

=head1 SYNOPSIS

    use Catmandu::Sane;

    sub be_naughty {
        Catmandu::BadArg->throw("very naughty") if shift;
    }

    try {
        be_naughty(1);
    } catch_case [
        'Catmandu::BadArg' => sub {
            say "sorry";
        }
    ];

=head1 CURRRENT ERROR HIERARCHY
    Throwable::Error
        Catmandu::Error
            Catmandu::BadVal
                Catmandu::BadArg
                    Catmandu::BadFixArg
            Catmandu::NotImplemented
            Catmandu::NoSuchPackage
                Catmandu::NoSuchFixPackage
            Catmandu::FixParseError
            Catmandu::FixError

=head1 SEE ALSO

L<Throwable>

=cut

1;
