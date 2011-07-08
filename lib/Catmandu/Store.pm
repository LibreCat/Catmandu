package Catmandu::Store;
use Catmandu::Sane;
use parent qw(Catmandu::Pluggable);
use Catmandu::Object
    default_collection => { default => sub { 'objects' } },
    collections => { default => sub { {} } };

sub collection {
    my ($self, $name) = @_;
    $name ||= $self->default_collection;
    $self->collections->{$name} ||= do {
        my $class = ref $self;
        $class = "${class}::Collection";
        $class->new(
            store => $self,
            name  => $name,
        );
    };
}

1;
