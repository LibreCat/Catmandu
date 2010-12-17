package Catmandu;

use 5.010;
use Carp;
use Catmandu::Project;
use Sub::Exporter -setup => {
    exports => [qw(
        project
    )],
};

sub project {
    state $project;
    if (@_) {
        $project and croak "Catmandu project can only be initialized once.";
        $project = Catmandu::Project->new(@_);
    }
    $project or croak "Catmandu project not initialized.";
}

1;

