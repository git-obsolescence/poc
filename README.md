# Git Obsolescence

This repo contains a proof of concept for git obsolescence. The goal is to keep
around the history of a change that goes through many `git --amend` and `git
rebase` revisions before finally merging into a public branch somewhere. Enough
history needs to be kept so that when conflicts arise, divergence will be
detected and git will have the information to do a merge between the two. When a
change is rebased or amended independently in two different workspaces, git
doesn't detect the conflict and it can be difficult to merge them together. This
aims to solve this problem.

This essentially gives us rebase-like control over exactly how the final
branch will look while at the same time making it as safe as branching and
merging without rewriting history: the best of both worlds.

The code in this repository is POC quality. Corners were cut here and there to
save time. For example, the tests are not broken out into small individual test
cases that are self-contained. Each script runs through a number of test steps
that build off of each other. This isn't the ideal way to write tests but was
condusive to getting the POC done in a shorter amount of time.

- git push runs three separate times and therefore is very slow
- git fetch is similarly slow due to having to hit the remote server multiple
  times.
- git pull is not supported. Use git fetch.
- git fetch from multiple remotes doesn't work

## How to use it

To use this POC, first ensure that the `git` command found under `./bin` is
ahead of regular git on `$PATH`. You can do this by putting `./bin` on the front
of `$PATH`.

    $ export PATH=$PWD/bin:$PATH

Alternatively, you can symlink it to a directory that is already ahead of
regular git on your `$PATH` if you have such a directory handy. It is important
that you symlink this and not copy because it will be through the link that the
script finds its origin.

You also need a git repository to work with and you need to configure it to turn
on obsolescence. Do this using `git config`.

   $ git config obsolescence.enabled true

It is helpful to mark upstream branches as stable. This will speed up comparing
changes in `git rebase` because it will not consider any changes on stable
branches as malleable and therefore will not attempt to reconcile your changes
with them. For example, the following command will tell it to consider the
origin remote's main branch as stable.

   $ git config remote.origin.stable main

You can use an existing "real" repository if you dare. Be careful with this
because you may end up having commits with useless "obsoletes:" trailers in the
commit message. They are harmless except that they could be confusing if they
end up getting merged into a public repository where most contributors aren't
aware of what they are for.

Also beware that this is POC quality code. It could do the wrong thing and leave
your repository in a state from which it is difficult, or beyond your
capability, to recover. You should be very familiar with the inner workings of
git. For now, be sure to run commands on a clean working copy and remember that
`git reflog` is your friend. You should be able to back up to a known good
state. Don't use it if you're not prepared for the consequences which could
include losing a significant amount of work from your local repository.
