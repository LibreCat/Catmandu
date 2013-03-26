package Catmandu::Exporter::Atom;

use namespace::clean;
use Catmandu::Sane;
use XML::Atom::Feed;
use XML::Atom::Entry;
use POSIX qw(strftime);
use Moo;

with 'Catmandu::Exporter';

has title       => (is => 'ro', default => sub { undef });
has subtitle    => (is => 'ro', default => sub { undef });
has id          => (is => 'ro', default => sub { undef });
has icon        => (is => 'ro', default => sub { undef });
has logo        => (is => 'ro', default => sub { undef });
has generator   => (is => 'ro', default => sub { undef });
has updated     => (is => 'ro', default => sub { undef });
has rights      => (is => 'ro', default => sub { undef });
has ns          => (is => 'ro', default => sub { undef });

has link        => (is => 'ro', isa => sub {
                    Catmandu::BadArg->throw("Link needs to be an array hash")
                        unless !defined $_[0] || ref $_[0] eq 'ARRAY';
                 });
has author      => (is => 'ro', isa => sub {
                    Catmandu::BadArg->throw("Author needs to be an array hash")
                        unless !defined $_[0] || ref $_[0] eq 'ARRAY';
                 });
has contributor => (is => 'ro', isa => sub {
                    Catmandu::BadArg->throw("Contributor needs to be an array hash")
                        unless !defined $_[0] || ref $_[0] eq 'ARRAY';
                 });
has category    => (is => 'ro', isa => sub {
                    Catmandu::BadArg->throw("Category needs to be an array hash")
                        unless !defined $_[0] || ref $_[0] eq 'ARRAY';
                 });

has atom        => (is => 'ro', lazy => 1, builder => '_build_atom');
has extra       => (is => 'ro', default => sub { undef });

sub BUILDARGS {
   my ( $class, @args ) = @_;
   my %args = ();
   
   if (@args > 0 && @args % 2 == 0) { 
    (%args) = (@args);
    for (keys %args) {
       next unless /^[^:]+:/;
       $args{extra}->{$_} = $args{$_};
    }
   }
   
   return \%args;
}
 
sub _build_atom {
    my ($self) = @_;
    my $atom = XML::Atom::Feed->new;
    
    if (defined $self->author) {
        for (@{$self->author}) {
             my $author = XML::Atom::Person->new;
             $author->name($_->{name}) if defined $_->{name};
             $author->email($_->{email}) if defined $_->{email};
             $author->uri($_->{uri}) if defined $_->{uri};
             $author->url($_->{url}) if defined $_->{url};
             $author->homepage($_->{homepage}) if defined $_->{homepage};
             $atom->author($author);
        }
    }
    
    if (defined $self->category) {
        for (@{$self->category}) {
             my $category = XML::Atom::Category->new;
             $category->term($_->{term}) if defined $_->{term};
             $category->label($_->{label}) if defined $_->{label};
             $category->scheme($_->{scheme}) if defined $_->{scheme};
             $atom->add_category($category, 'test');
        }
    }
    
    if (defined $self->contributor) {
        for (@{$self->contributor}) {
             my $contributor = XML::Atom::Person->new;
             $contributor->name($_->{name}) if defined $_->{name};
             $contributor->email($_->{email}) if defined $_->{email};
             $contributor->uri($_->{uri}) if defined $_->{uri};
             $contributor->url($_->{url}) if defined $_->{url};
             $contributor->homepage($_->{homepage}) if defined $_->{homepage};
             $atom->contributor($contributor);
        }
    }
    
    $atom->generator($self->generator) if defined $self->generator;
    $atom->icon($self->icon) if defined $self->icon;
    $atom->id($self->id) if defined $self->id; 
    
    if (defined $self->link) {
        for (@{$self->link}) {
             my $link = XML::Atom::Link->new;
             $link->type($_->{type}) if defined $_->{type};
             $link->rel($_->{rel}) if defined $_->{rel};
             $link->href($_->{href}) if defined $_->{href};
             $link->hreflang($_->{hreflang}) if defined $_->{hreflang};
             $link->title($_->{title}) if defined $_->{title};
             $link->lenth($_->{length}) if defined $_->{length};
             $atom->add_link($link);
        }
    }
    
    $atom->logo($self->logo) if defined $self->logo;
    $atom->rights($self->rights) if defined $self->rights;
    $atom->subtitle($self->subtitle) if defined $self->subtitle;    
    $atom->title($self->title) if defined $self->title;

    my $updated = $self->updated  ? $self->updated  : strftime("%Y-%m-%dT%H:%M:%SZ",gmtime(time));
    $atom->updated($updated);
    
    if (defined $self->ns) {
        for my $key (keys %{$self->extra}) {
            next unless $key =~ /^([^:]+):(\S+)/;
            my ($prefix,$name) = ($1,$2);
            my $url = $self->ns->{$prefix};
            next unless defined $url;
            my $ns  = XML::Atom::Namespace->new( $prefix => $url );
            my $value = $self->extra->{$key};
            $atom->set($ns, $name, $value);
        }
    }
    
    $atom;
}

sub add {
    my ($self, $data) = @_;
    my $entry = XML::Atom::Entry->new;
 
    if (defined $data->{author}->{name} || defined $data->{author}->{email}) {
        my $author = XML::Atom::Person->new;
        $author->name($data->{author}->{name}) if defined $data->{author}->{name};
        $author->email($data->{author}->{email}) if defined $data->{author}->{email};
        $author->uri($data->{author}->{uri}) if defined $data->{author}->{uri};
        $author->url($data->{author}->{url}) if defined $data->{author}->{url};
        $author->homepage($data->{author}->{homepage}) if defined $data->{author}->{homepage};
        $entry->author($author);
    }
    
    if (defined $data->{category}) {
        for (@{$data->{category}}) {
            my $category = XML::Atom::Category->new;
            $category->term($_->{term}) if defined $_->{term};
            $category->label($_->{label}) if defined $_->{label};
            $category->scheme($_->{scheme}) if defined $_->{scheme};
            $entry->add_category($category);
        }
    }
    
    if (defined $data->{content}) {
        my $content = XML::Atom::Content->new;
        $content->mode($data->{content}->{mode} ? $data->{content}->{mode} : "xml");
        $content->body($data->{content}->{body});
        $entry->content($content);
    }
    
    if (defined $data->{contributor}->{name} || defined $data->{contributor}->{email}) {
           my $contributor = XML::Atom::Person->new;
           $contributor->name($data->{contributor}->{name}) if defined $data->{contributor}->{name};
           $contributor->email($data->{contributor}->{email}) if defined $data->{contributor}->{email};
           $contributor->uri($data->{contributor}->{uri}) if defined $data->{contributor}->{uri};
           $contributor->url($data->{contributor}->{url}) if defined $data->{contributor}->{url};
           $contributor->homepage($data->{contributor}->{homepage}) if defined $data->{contributor}->{homepage};
           $entry->contributor($contributor);
    }
    
    $entry->id($data->{id}) if defined $data->{id}; 
    
    if (defined $data->{link}) {
        for (@{$data->{link}}) {
            my $link = XML::Atom::Link->new;
            $link->type($_->{type}) if defined $_->{type};
            $link->rel($_->{rel}) if defined $_->{rel};
            $link->href($_->{href}) if defined $_->{href};
            $link->hreflang($_->{hreflang}) if defined $_->{hreflang};
            $link->title($_->{title}) if defined $_->{title};
            $link->length($_->{length}) if defined $_->{length};
            $entry->add_link($link);
        }
    }
    
    my $published = $data->{published} ? $data->{published} : strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time));
    $entry->published($published);
    
    $entry->rights($data->{rights}) if defined $data->{rights};
    $entry->source($data->{source}) if defined $data->{source};
    $entry->summary($data->{summary}) if defined $data->{summary};
    $entry->title($data->{title}) if defined $data->{title}; 
   
    my $updated = $data->{updated} ? $data->{updated} : strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time));
    $entry->updated($updated);
    
    # Other metadata can be in a namespace
    if (defined $self->ns) {
        for my $key (keys %{$data}) {
            next unless $key =~ /^([^:]+):(\S+)/;
            my ($prefix,$name) = ($1,$2);
            my $url = $self->ns->{$prefix};
            next unless defined $url;
            my $ns  = XML::Atom::Namespace->new( $prefix => $url );
            my $value = $data->{$key};
            $entry->set($ns, $name, $value);
        }
    }
    
    $self->atom->add_entry($entry);
}

sub commit {
    my ($self) = @_;
    my $fh = $self->fh;
    say $fh $self->atom->as_xml;
}

=head1 NAME

Catmandu::Exporter::Atom - a Atom exporter

=head1 SYNOPSIS

    use Catmandu::Exporter::Atom;

    my $blog_args = {
     id => "urn:uuid:60a76c80-d399-11d9-b91C-0003939e0af6" ,
     title => "My Blog" , 
     subtitle => "testing 1.2.3" ,
     icon => "http://icons.org/test.jpg" ,
     generator => "Catmandu::Exporter::Atom" ,
     rights => "Beer license",
     link => [
                {
         'type' => 'text/html' ,
         'rel'  => 'alternate' ,
         'href' => 'http://www.example.com' ,
                 } 
     ],
     author => [ 
               {
         'name' => 'Daffy' ,
         'email' => 'duck@toons.be' ,
               }
     ] ,
     contributor => [
                {
          'name'  => 'Bugs' ,
          'email' => 'bunny@toons.be'
                }
     ],
     ns => {
         'dc' => 'http://purl.org/dc/elements/1.1/',
     },
     'dc:source' => 'test',
    };
    
    my $exporter = Catmandu::Exporter::Atom->new(%$blog_args);

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);
    
    $exporter->add({
     'title'    => 'My Little Pony' ,
     'subtitle' => 'Data testing for you and me' ,
     'content'  => "sdsadas" ,
     'summary'  => 'Brol 123' ,
     'id'       => '1291821827128172817' ,
     'author' => {
        'name' => 'John Doe' ,
        'email' => 'john@farwaway.org' ,
     } ,
     'contributor' => {
        'name' => 'Rabbit, R' ,
        'email' => 'r.rabbit@farwaway.org' ,
        'homepage' => 'http://faraway.org/~rabbit' ,
     } ,
     'link' => [
               {
        'type' => 'text/html' ,
        'rel'  => 'alternate' ,
        'href' => 'http://www.example.com' ,
        'title' => 'Test test' ,
        'length' => '1231' ,
        'hreflang' => 'eng' ,
                } ,
               {
        'type' => 'text/html' ,
        'rel'  => 'alternate' ,
        'href' => 'http://www.example2.com' ,
                }
     ] ,
     'category' => [
                {
        'scheme' => 'http://localhost:8080/roller/adminblog' ,
        'term' => 'Music',
                }
     ] ,
     'rights' => 'Yadadada',
     'dc:subject' => 'Toyz',
    });

    printf "exported %d objects\n" , $exporter->count;

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut

1;
