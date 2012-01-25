package Dancer::Plugin::Catmandu::SRU;

our $VERSION = '0.1';

use Catmandu::Sane;
use Dancer::Plugin;
use Dancer qw(:syntax);
use Catmandu;
use Catmandu::Fix;
use Catmandu::Exporter::Template;
use SRU::Request;
use SRU::Response;

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
            $schema->{fix} = Catmandu::Fix->new(fixes => $fix);
        }
        $hash->{$identifier} = $schema;
        $hash->{$short_name} = $schema;
    }
    $hash;
};

sub sru_provider {
    my ($path) = @_;

    my $bag = Catmandu::store($setting->{store})->bag($setting->{bag});

    get $path => sub {
        content_type 'xml';

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
                my $cql = $request->query;
                if ($setting->{filter}) {
                    $cql = "($setting->{filter}) and ($cql)";
                }

                my $start = $request->startRecord || 0;
                my $limit = $request->maximumRecords || 20;
                if ($limit > 1000) {
                    $limit = 1000;
                }

                my $hits = $bag->search(
                    cql_query => $cql,
                    sru_sortkeys => $request->sortKeys,
                    limit => $limit,
                    start => $start,
                );
                $hits->each(sub {
                    my $data = $_[0];
                    my $metadata = "";
                    my $exporter = Catmandu::Exporter::Template->new(
                        template => $template,
                        file => \$metadata,
                        fix => $fix,
                    );
                    $exporter->add($data);
                    $exporter->commit;
                    $response->addRecord(SRU::Response::Record->new(
                        recordSchema => $identifier,
                        recordData => $metadata,
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
