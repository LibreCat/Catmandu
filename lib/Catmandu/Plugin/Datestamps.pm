package Catmandu::Plugin::Datestamps;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Catmandu::Util qw(check_string now);
use Moo::Role;
use MooX::Aliases;
use namespace::clean;

has datestamp_format => (is => 'lazy');
has datestamp_created_key => (
    is    => 'lazy',
    isa   => \&check_string,
    alias => 'datestamp_created_field',
);
has datestamp_updated_key => (
    is    => 'lazy',
    isa   => \&check_string,
    alias => 'datestamp_updated_field',
);

before add => sub {
    my ($self, $data) = @_;

    my $now = now($self->datestamp_format);

    $data->{$self->datestamp_created_key} ||= $now;
    $data->{$self->datestamp_updated_key} = $now;
};

sub _build_datestamp_format      {'iso_date_time'}
sub _build_datestamp_created_key {'date_created'}
sub _build_datestamp_updated_key {'date_updated'}

1;

__END__

=pod

=head1 NAME

Catmandu::Plugin::Datestamps - Automatically add datestamps to Catmandu::Store records

=head1 SYNOPSIS

 # Using configuration files

 $ cat catmandu.yml
 ---
 store:
  test:
    package: MongoDB
    options:
      database_name: test
      bags:
        data:
          plugins:
            - Datestamps

 $ echo '{"hello":"world"}' | catmandu import JSON to test
 $ catmandu export test to YAML
 ---
 _id: ADA305D8-697D-11E3-B0C3-97AD572FA7E3
 date_created: 2013-12-20T13:50:25Z
 date_updated: 2013-12-20T13:50:25Z
 hello: world

 # Or in your Perl program
 my $store = Catmandu::Store::MongoDB->new(
            database_name => 'test' ,
            bags => {
                data => {
                plugins => [qw(Datestamps)]
            }
        });

 $store->bag->add({
        '_id'  => '123',
        'name' => 'John Doe'
 });

 my $obj = $store->bag->get('123');

 print "%s created at %s\n" , $obj->{name} , $obj->{date_created};

=head1 DESCRIPTION

The Catmandu::Plugin::Datestamps plugin automatically adds/updates datestamp fields in your
records. If you add this plugin to your Catmandu::Store configuration then automatically a 
'date_created' and 'date_updated' field gets added to newly ingested records.

The plugin should be set for every bag defined in your Catmandu::Store. In the examples above we've
set the plugin to the default bag 'data' that is created in every Catmandu::Store.

In Catmandu::Store-s that don't have a dynamic schema (e.g. Solr, DBI) these new date fields should be
predefined (e.g by changing the schema.xml or tables fields).

=head1 CONFIGURATION

=over

=item datestamp_created_key

Field name where the creation date is stored. Defaults to 'date_created'. Also
aliased as C<datestamp_created_field>.

=item datestamp_updated_key

Field name where the update date is stored. Defaults to 'date_updated'. Also
aliased as C<datestamp_updated_field>.

=item datestamp_format

Use a custom C<strftime> format. See L<Catmandu::Util::now> for possible format values.

    my $store = Catmandu::Store::MyDB->new(bags => {book => {plugins =>
        ['Datestamps'], datestamp_format => '%Y/%m/%d'}});

    my $store = Catmandu::Store::MyDB->new(bags => {book => {plugins =>
        ['Datestamps'], datestamp_format => 'iso_date_time_millis'}});

=back

=head1 SEE ALSO

L<Catmandu::Store>, L<Catmandu::Bag>

=cut
