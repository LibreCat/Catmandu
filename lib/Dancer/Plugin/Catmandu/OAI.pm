package Dancer::Plugin::Catmandu::OAI; # TODO deletedRecord=persistent, hierarchical sets, setDescription

our $VERSION = '0.0101';

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Catmandu;
use Catmandu::Fix;
use Catmandu::Exporter::Template;
use Dancer::Plugin;
use Dancer qw(:syntax);
use DateTime;

my $VERBS = {
    GetRecord => {
        valid    => {metadataPrefix => 1, identifier => 1},
        required => [qw(metadataPrefix identifier)],
    },
    Identify => {
        valid    => {},
        required => [],
    },
    ListIdentifiers => {
        valid    => {metadataPrefix => 1, from => 1, until => 1, set => 1, resumptionToken => 1},
        required => [qw(metadataPrefix)],
    },
    ListMetadataFormats => {
        valid    => {identifier => 1, resumptionToken => 1},
        required => [],
    },
    ListRecords => {
        valid    => {metadataPrefix => 1, from => 1, until => 1, set => 1, resumptionToken => 1},
        required => [qw(metadataPrefix)],
    },
    ListSets => {
        valid    => {resumptionToken => 1},
        required => [],
    },
};

my $setting = plugin_setting;

my $metadata_formats = do {
    my $list = $setting->{metadata_formats};
    my $hash = {};
    for my $format (@$list) {
        my $prefix = $format->{metadataPrefix};
        $format = {%$format};
        if (my $fix = $format->{fix}) {
            $format->{fix} = Catmandu::Fix->new(fixes => $fix);
        }
        $hash->{$prefix} = $format;
    }
    $hash;
};

my $sets = do {
    if (my $list = $setting->{sets}) {
        my $hash = {};
        for my $set (@$list) {
            my $key = $set->{setSpec};
            $hash->{$key} = $set;
        }
        $hash;
    } else {
        0;
    }
};

my $ns = "oai:$setting->{repositoryIdentifier}:";

my $template_header = <<TT;
<?xml version="1.0" encoding="UTF-8"?>
<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">
<responseDate>[% response_date %]</responseDate>
[%- IF params.resumptionToken %]
<request verb="[% params.verb %]" resumptionToken="[% params.resumptionToken %]">[% request_uri | xml %]</request>
[%- ELSE %]
<request[% FOREACH param IN params %] [% param.key %]="[% param.value | xml %]"[% END %]>[% request_uri | xml %]</request>
[%- END %]
TT

my $template_footer = <<TT;
</OAI-PMH>
TT

my $template_error = <<TT;
$template_header
[%- FOREACH error IN errors %]
<error code="[% error.0 %]">[% error.1 | xml %]</error>
[%- END %]
$template_footer
TT

my $template_record_header = <<TT;
<header[% IF deleted %] status="deleted"[% END %]>
    <identifier>${ns}[% id %]</identifier>
    <datestamp>[% datestamp %]</datestamp>
    [%- FOREACH s IN setSpec %]
    <setSpec>[% s %]</setSpec>
    [%- END %]
</header>
TT

my $template_get_record = <<TT;
$template_header
<GetRecord>
<record>
$template_record_header
[%- UNLESS deleted %]
<metadata>
[% metadata %]
</metadata>
[%- END %]
</record>
</GetRecord>
$template_footer
TT

my $template_identify = <<TT;
$template_header
<Identify>
<repositoryName>$setting->{repositoryName}</repositoryName>
<baseURL>[% request.uri %]</baseURL>
<protocolVersion>2.0</protocolVersion>
<earliestDatestamp>$setting->{earliestDatestamp}</earliestDatestamp>
<deletedRecord>$setting->{deletedRecord}</deletedRecord>
<granularity>YYYY-MM-DDThh:mm:ssZ</granularity>
<adminEmail>$setting->{adminEmail}</adminEmail>
<description>
    <oai-identifier xmlns="http://www.openarchives.org/OAI/2.0/oai-identifier"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai-identifier http://www.openarchives.org/OAI/2.0/oai-identifier.xsd">
        <scheme>oai</scheme>
        <repositoryIdentifier>$setting->{repositoryIdentifier}</repositoryIdentifier>
        <delimiter>$setting->{delimiter}</delimiter>
        <sampleIdentifier>$setting->{sampleIdentifier}</sampleIdentifier>
    </oai-identifier>
</description>
</Identify>
$template_footer
TT

my $template_list_identifiers = <<TT;
$template_header
<ListIdentifiers>
[%- FOREACH records %]
$template_record_header
[%- END %]
[%- IF token %]
<resumptionToken cursor="[% start %]" completeListSize="[% total %]">[% token %]</resumptionToken>
[%- ELSE %]
<resumptionToken cursor="[% start %]" completeListSize="[% total %]"/>
[%- END %]
</ListIdentifiers>
$template_footer
TT

my $template_list_records = <<TT;
$template_header
<ListRecords>
[%- FOREACH records %]
<record>
$template_record_header
[%- UNLESS deleted %]
<metadata>
[% metadata %]
</metadata>
[%- END %]
</record>
[%- END %]
[%- IF token %]
<resumptionToken cursor="[% start %]" completeListSize="[% total %]">[% token %]</resumptionToken>
[%- ELSE %]
<resumptionToken cursor="[% start %]" completeListSize="[% total %]"/>
[%- END %]
</ListRecords>
$template_footer
TT

my $template_list_metadata_formats = "";
$template_list_metadata_formats .= <<TT;
$template_header
<ListMetadataFormats>
TT
for my $format (values %$metadata_formats) {
$template_list_metadata_formats .= <<TT;
<metadataFormat>
    <metadataPrefix>$format->{metadataPrefix}</metadataPrefix>
    <metadataNamespace>$format->{metadataNamespace}</metadataNamespace>
    <schema>$format->{schema}</schema>
</metadataFormat>
TT
}
$template_list_metadata_formats .= <<TT;
</ListMetadataFormats>
$template_footer
TT

my $template_list_sets = <<TT;
$template_header
<ListSets>
TT
for my $set (values %$sets) {
$template_list_sets .= <<TT;
<set>
    <setSpec>$set->{setSpec}</setSpec>
    <setName>$set->{setName}</setName>
</set>
TT
}
$template_list_sets .= <<TT;
</ListSets>
$template_footer
TT

sub render {
    my $out = "";
    Catmandu::Exporter::Template->tt->process(@_, \$out);
    $out;
}

sub oai_provider {
    my ($path, %opts) = @_;

    my $sub_deleted = $opts{deleted} || sub { 0 };
    my $sub_set_specs_for = $opts{set_specs_for} || sub { [] };

    my $bag = Catmandu->store($opts{store} || $setting->{store})->bag($opts{bag} || $setting->{bag});

    any ['get', 'post'] => $path => sub {
        my $response_date = DateTime->now->iso8601.'Z';
        my $params = request->is_get ? params('query') : params('body');
        my $errors = [];
        my $format;
        my $set;
        my $verb = $params->{verb};
        my $vars = {
            request_uri => request->uri_for($path),
            response_date => $response_date,
            errors => $errors,
        };

        if ($verb and my $spec = $VERBS->{$verb}) {
            my $valid = $spec->{valid};
            my $required = $spec->{required};

            if ($valid->{resumptionToken} and exists $params->{resumptionToken}) {
                if (keys(%$params) > 2) {
                    push @$errors, [badArgument => "resumptionToken cannot be combined with other parameters"];
                }
            } else {
                for my $key (keys %$params) {
                    next if $key eq 'verb';
                    unless ($valid->{$key}) {
                        push @$errors, [badArgument => "parameter $key is illegal"];
                    }
                }
                for my $key (@$required) {
                    unless (exists $params->{$key}) {
                        push @$errors, [badArgument => "parameter $key is missing"];
                    }
                }
            }
        } else {
            push @$errors, [badVerb => "illegal OAI verb"];
        }

        if (@$errors) {
            return render(\$template_error, $vars);
        }

        $vars->{params} = $params;

        if ($params->{resumptionToken}) {
            unless (is_string($params->{resumptionToken})) {
                push @$errors, [badResumptionToken => "resumptionToken is not in the correct format"];
            }

            if ($verb eq 'ListSets') {
                push @$errors, [badResumptionToken => "resumptionToken isn't necessary"];
            } else {
                my @parts = split '!', $params->{resumptionToken};

                unless (@parts == 5) {
                    push @$errors, [badResumptionToken => "resumptionToken is not in the correct format"];
                }

                $params->{set}            = $parts[0];
                $params->{from}           = $parts[1];
                $params->{until}          = $parts[2];
                $params->{metadataPrefix} = $parts[3];
                $vars->{start} = $parts[4];
            }
        }

        if ($params->{set}) {
            unless ($sets) {
                push @$errors, [noSetHierarchy => "sets are not supported"];
            }
            unless ($set = $sets->{$params->{set}}) {
                push @$errors, [badArgument => "set does not exist"];
            }
        }

        if (my $prefix = $params->{metadataPrefix}) {
            unless ($format = $metadata_formats->{$prefix}) {
                push @$errors, [cannotDisseminateFormat => "metadataPrefix $prefix is not supported"];
            }
        }

        if (@$errors) {
            return render(\$template_error, $vars);
        }

        content_type 'xml';

        if ($verb eq 'GetRecord') {
            my $id = $params->{identifier};
            $id =~ s/^$ns//;
            if (my $rec = $bag->get($id)) {
                $vars->{id} = $id;
                $vars->{datestamp} = _combined_utc_datestamp($rec->{$setting->{datestamp_field}});
                $vars->{deleted} = $sub_deleted->($rec);
                $vars->{setSpec} = $sub_set_specs_for->($rec);
                my $metadata = "";
                my $exporter = Catmandu::Exporter::Template->new(
                    template => $format->{template},
                    file => \$metadata,
                    fix => $format->{fix},
                );
                $exporter->add($rec);
                $exporter->commit;
                $vars->{metadata} = $metadata;
                unless ($vars->{deleted} and $setting->{deletedRecord} eq 'no') {
                    return render(\$template_get_record, $vars);
                }
            }
            push @$errors, [idDoesNotExist => "identifier $params->{identifier} is unknown or illegal"];
            return render(\$template_error, $vars);

        } elsif ($verb eq 'Identify') {
            return render(\$template_identify, $vars);

        } elsif ($verb eq 'ListIdentifiers' || $verb eq 'ListRecords') {
            my $limit = 100;
            my $start = $vars->{start} //= 0;
            my $from  = $params->{from};
            my $until = $params->{until};

            for my $datestamp (($from, $until)) {
                $datestamp || next;
                if ($datestamp !~ /^\d{4}-\d{2}-\d{2}(?:T\d{2}:\d{2}:\d{2}Z)?$/) {
                    push @$errors, [badArgument => "datestamps must have the format YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ"];
                    return render(\$template_error, $vars);
                };
            }

            if ($from && $until && length($from) != length($until)) {
                push @$errors, [badArgument => "datestamps must have the same granularity"];
                return render(\$template_error, $vars);                
            }

            if ($from && $until && $from gt $until) {
                push @$errors, [badArgument => "from is more recent than until"];
                return render(\$template_error, $vars);
            }

            if ($from && length($from) > 10) {
                substr $from, 10, 1, " ";
                substr $from, 19, 1, "";
            } elsif ($from) {
                $from = "$from 00:00:00";
            }
            if ($until && length($until) > 10) {
                substr $until, 10, 1, " ";
                substr $until, 19, 1, "";
            } elsif ($until) {
                $until = "$until 00:00:00";
            }

            my @cql;

            push @cql, "($setting->{filter})"                        if $setting->{filter};
            push @cql, "($set->{cql})"                               if $set && $set->{cql};
            push @cql, "($setting->{datestamp_field} >= \"$from\")"  if $from;
            push @cql, "($setting->{datestamp_field} <= \"$until\")" if $until;
            unless (@cql) {
                push @cql, "(cql.allRecords)";
            }

            my $search = $bag->search(cql_query => join(' AND ', @cql), limit => $limit, start => $start);
            unless ($search->total) {
                push @$errors, [noRecordsMatch => "no records found"];
                return render(\$template_error, $vars);
            }
            if ($start + $limit < $search->total) {
                $vars->{token} = join '!', $params->{set} || '', $from || '', $until || '', $params->{metadataPrefix}, $start + $limit;
            }
            $vars->{total} = $search->total;

            if ($verb eq 'ListIdentifiers') {
                $vars->{records} = [map {
                    my $rec = $_;
                    {
                        id => $rec->{_id},
                        datestamp => _combined_utc_datestamp($rec->{$setting->{datestamp_field}}),
                        deleted => $sub_deleted->($rec),
                        setSpec => $sub_set_specs_for->($rec),
                    };
                } @{$search->hits}];
                return render(\$template_list_identifiers, $vars);
            } else {
                $vars->{records} = [map {
                    my $rec = $_;
                    my $deleted = $sub_deleted->($rec);
                    my $metadata;
                    unless ($deleted) {
                        $metadata = "";
                        my $exporter = Catmandu::Exporter::Template->new(
                            template => $format->{template},
                            file => \$metadata,
                            fix => $format->{fix},
                        );
                        $exporter->add($rec);
                        $exporter->commit;
                    }
                    {
                        id => $rec->{_id},
                        datestamp => _combined_utc_datestamp($rec->{$setting->{datestamp_field}}),
                        deleted => $deleted,
                        setSpec => $sub_set_specs_for->($rec),
                        metadata => $metadata,
                    };
                } @{$search->hits}];
                return render(\$template_list_records, $vars);
            }

        } elsif ($verb eq 'ListMetadataFormats') {
            if (my $id = $params->{identifier}) {
                $id =~ s/^$ns//;
                unless ($bag->get($id)) {
                    push @$errors, [idDoesNotExist => "identifier $params->{identifier} is unknown or illegal"];
                    return render(\$template_error, $vars);
                }
            }
            return render(\$template_list_metadata_formats, $vars);

        } elsif ($verb eq 'ListSets') {
            return render(\$template_list_sets, $vars);
        }
    }
};

sub _combined_utc_datestamp {
    my $date = $_[0];
    if ($date) {
        $date = "${date}T00:00:00" unless length($date) > 10;
        $date = "${date}:00"       unless length($date) > 16;
        substr $date, 10, 1, "T";
        substr $date, 19, 1, "Z";
    }
    $date;
}

register oai_provider => \&oai_provider;

register_plugin;

1;
