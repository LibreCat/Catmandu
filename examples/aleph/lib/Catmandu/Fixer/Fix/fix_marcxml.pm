package Catmandu::Fixer::Fix::fix_marcxml;
# VERSION
use Moose;
use Catmandu::Fixer::Util qw(path_and_field path_values);

extends qw(Catmandu::Fixer::Fix);

has [qw(path field)] => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $field) = @_;
    (my $path, $field) = path_and_field($field);
    { path      => $path,
      field     => $field };
};

sub apply_fix {
    my ($self, $obj) = @_;

    my $field  = $self->field;
   
    my $fixer = \&_tomarcxml;

    if (my $path = $self->path) {
        for my $o ($path->values($obj)) {
            $o->{$field} = $self->_fixme($o->{$field}, $fixer);
        }
    } else {
        $obj->{$field} = $self->_fixme($obj->{$field}, $fixer);
    }

    $obj;
};

sub _fixme {
    my ($self,$val, $callback) = @_;

    if (ref $val eq 'ARRAY') {
        [ map { $callback->($_)  } @$val ];
    } else {
        $callback->($val);
    }
}

sub _tomarcxml {
    my $val = shift;

    my $sysid = $val->{sysid};
    my $data  = $val->{data};

    my $xml =<<EOF;
<marc:record xmlns:marc="http://www.loc.gov/MARC21/slim">
EOF

    foreach my $field (@$data) {
        my ($field,$ind1,$ind2,$char,@parts) = @$field;
        next if $field eq 'FMT';
    
        if (index($field,"00") == 0) {
            my $value = $parts[1];
            $value = &_escape($value);

            $xml .=<<EOF;
<marc:controlfield tag="$field">$value</marc:controlfield>
EOF
        }
        elsif ($field =~ /\d{3}|CAT|Z30|STA|L\d{2}/) {
            $xml .=<<EOF;
<marc:datafield ind1="$ind1" ind2="$ind2" tag="$field">
EOF
            INNER: while (@parts) {
                my ($subfield,$value) = splice(@parts,0,2);
                next INNER if $subfield eq '_';
                $value = &_escape($value);
                $xml .= <<EOF;
<marc:subfield code="$subfield">$value</marc:subfield>

EOF
            }
            $xml .=<<EOF;
</marc:datafield>
EOF
        }
    }

    $xml .= <<EOF;
</marc:record>
EOF

    $xml;
}

sub _escape {
    $_ = shift;

    return "" unless $_;

    s/&/\&amp;/g;
    s/</\&lt;/g;
    s/>/\&gt;/g;
    s/'/\&apos;/g;
    s/"/\&quot;/g;

    $_;
}

__PACKAGE__->meta->make_immutable;

no Moose;
no Catmandu::Fixer::Util;

1;

