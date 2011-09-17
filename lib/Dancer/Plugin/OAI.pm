package Dancer::Plugin::OAI;
use strict;
use warnings;
use Dancer::Plugin;
use Dancer qw(:syntax);
use Catmandu::Fix;
use Template;
use DateTime;

our $VERSION = '0.1';

my $setting = plugin_setting;

my $metadata_formats = do {
    my $list = $setting->{metadata_formats};
    my $hash = {};
    for my $format (@$list) {
        my $prefix = $format->{metadataPrefix};
        $format = {%$format};
        if (my $fix = $format->{fix}) {
            $format->{fix} = Catmandu::Fix->new(@$fix);
        }
        $hash->{$prefix} = $format;
    }
    $hash;
};

my $verbs = {
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

my $template_header = <<TT;
<?xml version="1.0" encoding="UTF-8"?>
<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">
<responseDate>[% response_date %]</responseDate>
<request[% FOREACH param IN params('query') %] [% param.key %]="[% param.value | xml %]"[% END %]>[% request_uri | xml %]</request>
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

my $template_get_record = <<TT;
$template_header
<GetRecord>
<record>
<header[% IF deleted %] status="deleted"[% END %]>
    <identifier>[% params.identifier %]</identifier>
    <datestamp>[% datestamp %]</datestamp>
</header>
[%- UNLESS deleted %]
<metadata>
[% record %]
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
<granularity>$setting->{granularity}</granularity>
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
</ListIdentifiers>
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

my $template_list_records = <<TT;
$template_header
<ListRecords>
</ListRecords>
$template_footer
TT

my $template_list_sets = <<TT;
$template_header
<ListSets>
</ListSets>
$template_footer
TT

my $renderer;

sub render {
    $renderer ||= Template->new;
    my $out = "";
    $renderer->process(@_, \$out);
    $out;
}

sub oai_provider {
    my ($path, %opts) = @_;

    get $path => sub {
        my $response_date = DateTime->now->iso8601.'Z';
        my $params = params('query');
        my $errors = [];
        my $format;
        my $verb = $params->{verb};
        my $vars = {
            request_uri => request->uri_for($path),
            response_date => $response_date,
            errors => $errors,
        };

        if ($verb and my $spec = $verbs->{$verb}) {
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

        if (my $prefix = $params->{metadataPrefix}) {
            $format = $metadata_formats->{$prefix};
            unless ($format) {
                push @$errors, [cannotDisseminateFormat => "metadataPrefix $prefix is not supported"];
                return render(\$template_error, $vars);
            }
        }

        content_type 'text/xml; charset=utf-8';

        if ($verb eq 'GetRecord') {
            if (my $record = $opts{record}->($params->{identifier})) {
                $vars->{datestamp} = $opts{datestamp}->($record);
                $vars->{deleted} = $opts{deleted}->($record);
                $vars->{get} = template($format->{template}, $format->{fix} ? $format->{fix}->fix($record) : $record, {layout => $format->{layout}});
                unless ($vars->{deleted} and $setting->{deletedRecord} eq 'no') {
                    return render(\$template_get_record, $vars);
                }
            }
            push @$errors, [idDoesNotExist => "identifier $params->{identifier} is unknown or illegal"];
            return render(\$template_error, $vars);
        } elsif ($verb eq 'Identify') {
            return render(\$template_identify, $vars);
        } elsif ($verb eq 'ListIdentifiers') {
            return render(\$template_list_identifiers, $vars);
        } elsif ($verb eq 'ListMetadataFormats') {
            return render(\$template_list_metadata_formats, $vars);
        } elsif ($verb eq 'ListRecords') {
            return render(\$template_list_records, $vars);
        } elsif ($verb eq 'ListSets') {
            return render(\$template_list_sets, $vars);
        }
    }
};

register oai_provider => \&oai_provider;

register_plugin;

1;
