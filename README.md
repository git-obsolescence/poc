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
