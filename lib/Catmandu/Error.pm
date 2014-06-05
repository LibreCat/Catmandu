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

package Catmandu::ParseError;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::Error';

has source => (is => 'ro');

package Catmandu::FixError;
use namespace::clean;
use Catmandu::Sane;
use Moo;
extends 'Catmandu::Error';

has data   => (is => 'ro');
has fix    => (is => 'ro');

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
            Catmandu::NotImplemented
            Catmandu::NoSuchPackage
            Catmandu::ParseError
            Catmandu::FixError

=head1 SEE ALSO

L<Throwable>

=cut

1;
