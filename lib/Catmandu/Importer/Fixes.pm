package Catmandu::Importer::Fixes;
use Catmandu::Sane;
use Moo;
use Catmandu::Importer::Module::Info;

with 'Catmandu::Importer';

has local => (
    is => 'ro',
    default => sub { 1; }
);

sub generator {
    my ($self) = @_;
    sub {
        state $loaded = 0;
        state $modules = [];

        unless($loaded){
            Catmandu::Importer::Module::Info->new(
                local => $self->local,
                max_depth => 4,
                namespace => "Catmandu::Fix"
            )->each(sub{
                my $record = $_[0];
                #filter real fixes
                my(@parts)= split ':',$record->{name};
                push @$modules,$record if $parts[-1] =~ /^[a-z][0-9a-z_]+$/o;
            });
            $loaded = 1;
        }

        shift @$modules;

    };
}

1;
