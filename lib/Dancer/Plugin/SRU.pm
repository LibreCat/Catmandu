package Dancer::Plugin::SRU;
use Catmandu::Sane;
use Dancer::Plugin;
use Dancer qw(:syntax);
use Dancer::Plugin::Catmandu;
use Catmandu::Fix;
use SRU::Request;
use SRU::Response;

our $VERSION = '0.1';

my $setting = plugin_setting;

my $default_record_schema = $setting->{default_record_schema};

my $record_schemas = do {
    my $list = $setting->{record_schemas};
    my $hash = {};
    for my $schema (@$list) {
        $schema = {%$schema};
        my $identifier = $schema->{identifier};
        my $short_name = $schema->{short_name};
        if (my $fix = $schema->{fix}) {
            $schema->{fix} = Catmandu::Fix->new(@$fix);
        }
        $hash->{$identifier} = $schema;
        $hash->{$short_name} = $schema;
    }
    $hash;
};

sub sru_provider {
    my ($path) = @_;

    my $index = Catmandu::get_index($setting->{index});

    get $path => sub {
        content_type 'text/xml';

        my $request = SRU::Request->newFromURI(request->uri);
        my $response = SRU::Response->newFromRequest($request);

        given ($response->type) {
            when ('explain') {
                confess "TODO";
            }
            when ('scan') {
                confess "TODO";
            }
            default {
                my $schema = $record_schemas->{$request->recordSchema || $default_record_schema};
                my $identifier = $schema->{identifier};
                my $fix = $schema->{fix};
                my $template = $schema->{template};
                my $layout = $schema->{layout};

                my $skip = $request->startRecord || 0;
                my $size = $request->maximumRecords || 20;
                if ($size > 1000) {
                    $size = 1000;
                }

                my $hits = $index->cql_search($request->query, size => $size, skip => $skip);
                $hits->each(sub {
                    my $obj = $_[0];
                    if ($fix) {
                        $obj = $fix->fix($obj);
                    }
                    my $rec = template $template, $obj, { layout => $layout }; 
                    $response->addRecord(SRU::Response::Record->new(
                        recordSchema => $identifier, 
                        recordData   => $rec
                    ));
                });
            }
        }
        return $response->asXML;
    };
};

register sru_provider => \&sru_provider;

register_plugin;

1;
