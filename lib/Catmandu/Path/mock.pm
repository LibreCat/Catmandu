package Catmandu::Path::mock;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Catmandu::Util qw(is_code_ref is_string);
use List::Util qw(any);
use Moo;
use namespace::clean;

with 'Catmandu::Path';

use overload '""' => sub {$_[0]->path};

sub getter {
    my ($self) = @_;
    my $key = $self->path;
    sub {
        my $data = $_[0];
        if (exists $data->{$key}) {
            return [$data->{$key}];
        }
        return [];
    };
}

sub setter {
    my $self = shift;
    my %opts = @_ == 1 ? (value => $_[0]) : @_;
    my $key = $self->path;

    if (exists $opts{value}) {
        my $value = $opts{value};
        return sub {
            my $data = $_[0];
            if (is_code_ref($value)) {
                $data->{$key} = $value->();
            } else {
                $data->{$key} = $value;
            }
            return;
        };
    }

    sub {
        my ($data, $value) = @_;
        if (is_code_ref($value)) {
            $data->{$key} = $value->();
        } else {
            $data->{$key} = $value;
        }
            return;
    };
}

sub creator { # same as setter in this simple case
    my $self = shift;
    $self->setter(@_);

}

sub updater {
    my $self = shift;
    my %opts = @_ == 1 ? (value => $_[0]) : @_;
    my $key = $self->path;

    if (my $predicates = $opts{if}) {
        return sub {
            my $data = $_[0];

            return unless exists $data->{$key};

            my $value = $data->{$key};

            for (my $i = 0; $i < @$predicates; $i += 2) {
                my $tests = $predicates->[$i];
                my $cb  = $predicates->[$i + 1];
                $tests = [$tests] if is_string($tests);
                $tests = [map { Catmandu::Util->can("is_$_") } @$tests];
                next unless any { $_->($value) } @$tests;
                $data->{$key} = $cb->($value);
                last;
            }

            return;
        };
    }
    elsif (exists $opts{value}) {
        my $cb = $opts{value};
        return sub {
            my $data = $_[0];
            $data->{$key} = $cb->($data->{$key}) if exists $data->{$key};
            return;
        };
    }

    sub {
        my ($data, $cb) = @_;
        $data->{$key} = $cb->($data->{$key}) if exists $data->{$key};
        return;
    };
}

sub deleter {
    my ($self) = @_;
    my $key = $self->path;
    sub {
        my $data = $_[0];
        delete $data->{$key};
        return;
    };
}

1;
