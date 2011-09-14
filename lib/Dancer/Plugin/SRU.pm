package Dancer::Plugin::SRU;
use strict;
use warnings;
use Dancer qw(:syntax);
use Dancer::Plugin;
use CQL::Parser;
use SRU::Request;
use SRU::Response;

our $VERSION = '0.1';

my $cql_parser = CQL::Parser->new;

sub sru_provider {
    my ($path, %opts) = @_;

    my $index = $opts{index};

    get $path => sub {
        content_type 'text/xml';

        my $request = SRU::Request->newFromURI(request->uri);
        my $response = SRU::Response->newFromRequest($request);

        if ($response->type eq 'explain') {

        } elsif ($response->type eq 'scan') {

        } elsif ($response->type eq 'searchRetrieve') {
            my $query;
            eval {
                $query = $cql_parser->parse($request->query);
            } or do {
                my $error = $@;
                $response->addDiagnostic(SRU::Response::Diagnostic->newFromCode(10, $error));
                return $response->asXML;
            };
            my $skip = $request->startRecord || 0;
            my $size = $request->maximumRecords || 1000;
            $size = 1000 if $size > 1000;
            my $hits = $index->search($query->toLucene, size => $size, skip => $skip);
        }

        return $response->asXML;
    };
};

register sru_provider => \&sru_provider;

register_plugin;

1;
