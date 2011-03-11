package Blogmandu;
use Catmandu::App;
use Catmandu::Store::Hash;

sub store {
    state $store = Catmandu::Store::Hash->with_plugins('Timestamps')->new;
}

sub posts {
    my @posts;
    app->store->each(sub{
        push @posts, $_[0];
    });
    [ sort { $b->{_created_at} cmp $a->{_created_at} } @posts ];
}

app->GET('/' => sub {
    app->render(index => {posts => app->posts});
});

# equivalent with subroutine attributes:
# sub index :GET('/') {
#     app->render(index => {posts => app->posts});
# }

# also equivalent:
# sub index :R('/', GET) {
#     app->render(index => {posts => app->posts});
# }

# also equivalent:
# sub index {
#     app->render(index => {posts => app->posts});
# }
# app->GET('/', run => 'index');

app->POST('/' => sub {
    my $errors = [];
    my $post = {};

    foreach (qw(title message)) {
        $post->{$_} = app->req->param($_) or push @$errors, "$_ is required";
    }

    app->store->save($post) unless @$errors;

    app->render(index => {
        posts  => app->posts,
        errors => $errors,
    });
});

app->psgi_app;
