package Catmandu::Fix::add_to_exporter;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path          => (fix_arg => 1);
has exporter_name => (fix_arg => 1);
has exporter_args => (fix_opt => 'collect');
has exporter      => (is      => 'lazy', init_arg => undef);

with 'Catmandu::Fix::SimpleGetValue';

sub _build_exporter {
    my ($self) = @_;
    Catmandu->exporter(
        $self->exporter_name,
        %{$self->exporter_args},
        autocommit => 1
    );
}

sub emit_value {
    my ($self, $var, $fixer) = @_;
    my $exporter_var = $fixer->capture($self->exporter);

    "${exporter_var}->add(${var});"
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::add_to_exporter - Export a record as side effect

=head1 SYNOPSIS
  
   # Export the data field values to a CSV file
   add_to_exporter(data,CSV,file => /tmp/test.txt, header => 1)

   # Export the complete record into a JSON file
   add_to_exporter(data,JSON,file => /tmp/test.json, pretty => 1)

   # In general, export a PATH to an EXPORTER with one ore more OPT0s
   add_to_exporter(PATH,EXPORTER, OPT1 => ... , OPT2 => ... , OPT3 => ... , ...)

   # Use the add_to_exporter to explode an ARRAY into many records
   # E.g.
   #   books:
   #     - title: Graphic Design Rules
   #       year: 2003
   #     - title: Urban Sketching
   #       year: 2013
   #     - title: Findus flyttar ut
   #       year: 2012
   # And a fix file: exporter.fix
   do with(path => books)
      add_to_exporter(.,JSON)
   end
   # You can get an output with 3 records using the command line function
   catmandu convert JSON to Null --fix exporter.fix < book.json
   
=head1 SEE ALSO

L<Catmandu::Fix> , L<Catmandu::Exporter>

=cut
