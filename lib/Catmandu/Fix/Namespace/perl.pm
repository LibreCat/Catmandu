package Catmandu::Fix::Namespace::perl;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Catmandu::Util qw(is_instance require_package);
use String::CamelCase qw(camelize);
use Moo;
use namespace::clean;

with 'Catmandu::Fix::Namespace';

sub load {
    my ($self, $name, $args, $type) = @_;
    my $ns = join('::', map {camelize($_)} split(/\./, $self->name));
    $ns = join('::', $ns, $type) if $type;

    my $pkg;
    try {
        $pkg = require_package($name, $ns);
    }
    catch_case [
        'Catmandu::NoSuchPackage' => sub {
            Catmandu::NoSuchFixPackage->throw(
                message      => "No such fix package: $name",
                package_name => $_->package_name,
                fix_name     => $name,
            );
        },
    ];
    try {
        $pkg->new(@$args);
    }
    catch {
        $_->throw if is_instance($_, 'Catmandu::Error');
        Catmandu::BadFixArg->throw(
            message      => $_,
            package_name => $pkg,
            fix_name     => $name,
        );
    };
}

1;
