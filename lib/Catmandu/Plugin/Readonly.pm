package Catmandu::Plugin::Readonly;

our $VERSION = '1.07';

use Moo::Role;
use MooX::Aliases;
use Package::Stash;
use namespace::clean;

sub BUILD {
    my ($self) = @_;
    my $name = ref($self->store);

    if ($self->store->does('Catmandu::Droppable')) {

        # Overwrite the drop method of the Catmandu::Store implementation
        my $stash = Package::Stash->new($name);
        $stash->add_symbol(
            '&drop' => sub {
                $self->log->warn("trying to drop a readonly store");
                my $err = Catmandu::NotImplemented->new("$name is readonly");
                return undef, $err;
            }
        );
    }
}

around add => sub {
    my ($orig, $self, $data) = @_;
    my $name = ref($self);
    $self->log->warn("trying to add to readonly store");
    my $err = Catmandu::NotImplemented->new("$name is readonly");
    return undef, $err;
};

around delete => sub {
    my ($orig, $self) = @_;
    my $name = ref($self);
    $self->log->warn("trying to delete from readonly store");
    my $err = Catmandu::NotImplemented->new("$name is readonly");
    return undef, $err;
};

around delete_all => sub {
    my ($orig, $self) = @_;
    my $name = ref($self);
    $self->log->warn("trying to delete_all on readonly store");
    my $err = Catmandu::NotImplemented->new("$name is readonly");
    return undef, $err;
};

around drop => sub {
    my ($orig, $self) = @_;
    my $name = ref($self);
    $self->log->warn("trying to drop a readonly store");
    my $err = Catmandu::NotImplemented->new("$name is readonly");
    return undef, $err;
};

1;

__END__

=pod

=head1 NAME

Catmandu::Plugin::Readonly - Make stores or bags read-only

=head1 SYNOPSIS

 $ cat catmandu.yml
 ---
 store:
  test:
    package: File::Simple
    options:
      default_plugins: [ 'Readonly']
      root: t/data

 # This will  fail, no files can be added to the 'test' store
 $ catmandu stream myfile.txt to test --bag 1 -id myfile.txt

 # This command will succeed only if the 'test' database contains
 # the 'sample.txt' file
 # catmandu stream test --bag 3 --id sample.txt

=head1 DESCRIPTION

The Catmandu::Plugin::Readonly will transform a Catmandu::Store or a Catmandu::Bag
in read-only mode: all writes, deletes and drops will be ignored.

This command will work on L<Catmandu::Store> and L<Catmandu::FileStore>
implementations.

=head1 SEE ALSO

L<Catmandu::Store>, L<Catmandu::Bag>

=cut
