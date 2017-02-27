1;

=pod

=encoding utf8

=head1 Patch Submission

The Catmandu development team uses GitHub to collaborate. We greatly appreciate L<contributions|Catmandu::Help::Contribution> submitted via L<GitHub|https://github.com/LibreCat>, as it makes tracking these contributions and applying them much, much easier. This gives your contribution a much better chance of being integrated into Catmandu quickly!

To help us achieve high-quality, stable releases, git-flow workflow is used to handle pull-requests, that means contributors must work on their I<dev> branch rather than on their I<master> (the I<master> branch should be touched only by the core dev team when preparing a release to CPAN; all ongoing development happens in branches which are merged to the I<dev> branch.)

Here is the workflow for submitting a patch:

=head2 1. Fork

Fork the repository L<http://github.com/LibreCat/Catmandu> (click "Fork")

=head2 2. Clone

Clone your fork to have a local copy using the following command:

    $ git clone git://github.com/$myname/Catmandu.git

=head2 3. Development branch

As a contributor, you should B<always> work on the I<dev> branch of your clone (I<master> is used only for building releases).

    $ git remote add upstream https://github.com/LibreCat/Catmandu.git
    $ git fetch upstream
    $ git checkout -b dev upstream/dev

This will create a local branch in your clone named I<dev> and that will track the official I<dev> branch. That way, if you have more or less commits than the upstream repo, you'll be immediately notified by git.

=head2 4. Topic branch

You want to isolate all your commits in a I<topic> branch, this will make the reviewing much easier for the core team and will allow you to continue working on your clone without worrying about different commits mixing together.

To do that, first create a local branch to build your pull request:

    # you should be in dev branch here
    $ git checkout -b pr/$name

Now you have created a local branch named I<pr/$name> where I<$name> is the name you want (it should describe the purpose of the pull request you're preparing).

=head2 5. Push

In that branch, do all the commits you need (the more the better) and when
   done, push the branch to your fork:

    # ... commits ...
    $ git push origin pr/$name

You are now ready to send a pull request.

=head2 6. Pull request

Send a I<pull request> via the GitHub interface. Make sure your pull request is based on the I<pr/$name> branch you've just pushed, so that it incorporates the appropriate commits only.

It's also a good idea to summarize your work in a report sent to the users mailing list (see below), in order to make sure the team is aware of it.

When the core team reviews your pull request, it will either accept (and then merge into I<dev>) or refuse your request.

If it's refused, try to understand the reasons explained by the team for the denial. Most of the time, communicating with the core team is enough to understand what the mistake was. Above all, please don't be offended.

=head2 7. Merge

If your pull-request is merged into I<dev>, then all you have to do is to remove your local and remote I<pr/$name> branch:

    $ git checkout dev
    $ git branch -D pr/$name
    $ git push origin :pr/$name

=head2 8. Pull

And then, of course, you need to sync your local I<dev> branch with the I<upstream>:

    $ git pull upstream dev
    $ git push origin dev

You're now ready to start working on a new pull request!

