package Catmandu::Fix::Condition::valid;

use Catmandu::Sane;

our $VERSION = '1.0605';

use Moo;
use Catmandu::Util qw(require_package);
use namespace::clean;
use Catmandu::Fix::Has;

has path      => (fix_arg => 1);
has name      => (fix_arg => 1);
has opts      => (fix_opt => 'collect');
has validator => (is      => 'lazy', init_arg => undef);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var, $fixer) = @_;
    my $validator_var = $fixer->capture($self->validator);
    "${validator_var}\->is_valid(${var})";
}

sub _build_validator {
    my ($self) = @_;
    require_package($self->name, 'Catmandu::Validator')->new($self->opts);
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

L<Catmandu::Fix>

=cut
