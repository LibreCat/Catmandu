package Catmandu::Plugin::Datestamps;

use namespace::clean;
use Catmandu::Sane;
use Role::Tiny;
use POSIX qw(strftime);

before add => sub {
    my ($self, $data) = @_;
    my $now = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time));
    $data->{date_created} ||= $now;
    $data->{date_updated} = $now;
};

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

=head1 SEE ALSO

L<Catmandu::Store>, L<Catmandu::Bag>

=cut

1;
