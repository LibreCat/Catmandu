use MooseX::Declare;

class Catmandu::Importer::JSON with Catmandu::Importer {
    use JSON ();

    method each (CodeRef $sub) {
        my $json = JSON->new->utf8(1);
        my $file = $self->file;
        my $load_one;
        my $n = 0;

        # find and remove the initial "["
        for (;;) {
            $file->sysread(my $buf, 65536) or confess $@;
            $json->incr_parse($buf); # doesn't parse in void context
            $json->incr_text =~ s/^\s*//;
            last if $load_one = $json->incr_text =~ m/^\{/;
            last if $json->incr_text =~ s/^\[\s*//x;
        }

        PARSE: for (;;) {
            # read data until we have a single object
            for (;;) {
                if (my $obj = $json->incr_parse) {
                    $sub->($obj);
                    $n++;

                    last PARSE if $load_one;

                    last;
                }

                $file->sysread(my $buf, 65536) or confess $@;
                $json->incr_parse($buf);
            }

            # read data until we get "," or the final "]"
            for (;;) {
                $json->incr_text =~ s/^\s*//;

                last PARSE if $json->incr_text =~ s/^\]//;

                last if $json->incr_text =~ s/^,//;

                if (length $json->incr_text) {
                    confess "JSON parse error near ", $json->incr_text;
                }

                $file->sysread(my $buf, 65536) or confess $@;
                $json->incr_parse($buf);
            }
        }

        $n;
    }
}

1;

