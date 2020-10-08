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

## How to use it

The `shell` command in the top of this repository is the entry point for using
the code in this repository. It spawns a sub-shell with `$PATH` adjusted
appropriately to activate it.

You also need a git repository to work with. When you run `shell` it will look
to see if your current working directory is part of one. If it is, it will
install necessary hooks into the repository to create an obsolescence graph of
your changes. When the script exits, it will clean up the hooks. The script will
refuse to run if there are already repository hooks in place. One consequence of
this is that the script is not reentrant. You can only run one instance of it
per repository copy.

You can use an existing "real" repository if you want. Be careful with this
because you may end up having commits with useless "obsoletes:" trailers in the
commit message. They are harmless except that they could be confusing if they
end up getting merged into a public repository where most contributors aren't
aware of what they are for.
