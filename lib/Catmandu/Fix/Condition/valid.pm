package Catmandu::Fix::Condition::valid;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util qw(require_package);
use namespace::clean;
use Catmandu::Fix::Has;

has path           => (fix_arg => 1);
has name           => (fix_arg => 1);
has validator_opts => (fix_opt => 'collect');
has validator      => (is      => 'lazy', init_arg => undef);

with 'Catmandu::Fix::Condition::Builder::Simple';

sub _build_value_tester {
    my ($self) = @_;
    my $validator = $self->validator;
    sub {
        $validator->is_valid($_[0]);
    }
}

sub _build_validator {
    my ($self) = @_;
    require_package($self->name, 'Catmandu::Validator')
        ->new($self->validator_opts);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::valid - Execute fixes if the data passes validation

=head1 SYNOPSIS

    # reject all items not conforming to a schema
    select valid('', JSONSchema, schema: "my/schema.json")

    # check the author field
    unless valid(author, JSONSchema, schema: "my/author.schema.json")
       ... # repair or give warning
    end

=head1 SEE ALSO

See L<Catmandu::Fix::validate> to check and get validation errors.

=cut
