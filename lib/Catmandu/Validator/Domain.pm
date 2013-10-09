package Catmandu::Validator::Domain;

use Data::Domain;
use Catmandu::Sane;
use Moo;


with  'Catmandu::Validator';

has 'domain' => (
    required => 1,
    is       => 'rw',
);


has 'which_domain' => (
    is   => 'rw',
    isa => sub {
        Catmandu::BadArg->throw( "which_domain should be a CODE reference") unless ref $_[0] eq 'CODE',
    },
);


sub validate_hash {
    my ($self, $data) = @_;

    my $domain = $self->select_domain($data)
        or Catmandu::Error->throw("Don't know which domain to use");

    my $error_messages = $domain->inspect($data);

    return $error_messages;
}


sub select_domain {
    my ($self, $data) = @_;

    return $self->domain unless defined $self->which_domain;
    return  $self->domain->{ &{$self->which_domain}($data) };
} 


=head1 NAME

Catmandu::Validator::Domain - Catmandu::Validator using Data::Domain

=head1 SYNOPSIS

    use Catmandu::Validator::Domain;


    my $domain = ...

    my $validator = Catmandu::Validator::Domain->new( domain => $domain ); 

    if ( $validator->validate($hashref) ) {
        save_record_in_database($hashref);
    } else {
        reject_form($validator->error_messages);
    }
    
    
    my $dissertation_domain =  '';
    my $journal_article_domain = '';
    
    
    my $domain_hash = {
        dissertation => $dissertation_domain,
        journal_article => $journal_article_domain,  
    };
    my $validator = Catmandu::Validator::Domain->new( domain => $domain_hash ); 

    my $new_options = {
        error_handler => sub {
            my ($data, $errors) = @_;
            if ($errors) {
                print "Validation Errors for record $data->{_id}:\n";
                print "Error message: $_->{message}\n" for @{$errors};
            }
        }
    };
    
    my $validated_arrayref = $validator->validate_many($arrayref, $new_options);


=head1 DESCRIPTION

Catmandu::Validator::Simple is ....

=head1 METHODS

new(domain => $domain)
new(domain => $hashref>, %options)

validation_handler should be a callback function that will take $hashref to a data record as argument.
Should return undef if the record passes validation otherwise return an error or an arrayref of errors.
error can either be simple error message string or a hashref to a more detailed error information. If a
hashref is used then it should include the error messages field as 'message'. Any other information is
optional.

The constructor also optionally takes the common options for Catmandu::Validator.


validate(...)

validate_many(...)

errors(...)

error_messages(...)


These are methods inherited from Catmandu::Validator.

=head1 SEE ALSO

L<Catmandu::Validator>

=cut

1;
