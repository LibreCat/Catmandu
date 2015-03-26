use Catmandu::Fix;

sub {
    my ($data, $reject) = @_;
    if ($data->{answer} == 2) {
        return $reject;
    } else {
        $data->{answer} ||= 42;
        return $data;
    }
}
