# verify_commit prints the sha1 of a valid commit and exits with 0. If the
# commit is not valid in the current repository, it exits non-zero
verify_commit() {
    # git rev-parse only verifies that the ref derefenences to a valid sha1.
    # It doesn't check that the commit is valid in the current repository.
    # git rev-parse --quiet --verify $commit

    git log -1 --pretty=%H $1 2>/dev/null
}

# list_obsoletes lists all of the commits that the given commit obsoletes
list_obsoletes() {
    local commit=$1
    git log -1 --pretty=%B $commit |
        git interpret-trailers --parse |
        awk '$1=="obsoletes:"{print$2}'
}

# The change id for any commit can be found by recursively traversing the first
# out edge of the obsolescence graph until you get to a leaf commit. The sha of
# the leaf commit is the change id.
#
# The one exception to the above rule is if the commit's parent also points to
# the same obsolete commit. This indicates that the original change was split
# into multiple changes. In that case, any split out commits are the start of a
# new change with a new id.
get_change_id() {
    local commit=$1

    local first_edge=$(list_obsoletes $commit | head -n 1)

    if [ -z "$first_edge" ]
    then
        verify_commit $commit
        return
    fi

    if verify_commit ${commit}~ >/dev/null
    then
        local first_parent_edge=$(list_obsoletes ${commit}~ | head -n 1)
        if [ "$first_edge" = "${first_parent_edge}" ]
        then
            verify_commit $commit
            return
        fi
    fi

    get_change_id ${first_edge}
}

# pin_change_recursive is a helper that shouldn't be called directly.
pin_change_recursive() {
    local change_id=$1
    local commit=$2

    for obsolete in $(list_obsoletes ${commit})
    do
        ref="refs/cheads/${change_id}/${obsolete}"
        if ! verify_commit ${ref} >/dev/null
        then
            git update-ref ${ref} ${obsolete}
            pin_change_recursive ${change_id} ${obsolete}
        fi
    done
}

# Obsolete commits are orphaned as far as git is concerned. This means they
# will eventually be pruned from object storage unless something is done to
# keep them around.
#
# To accomplish this, this writes a reference for each orphaned commit
# under the refs/cheads/ namespace. They are organized by the change id of the
# change to which they belong.
#
# pin_change fills in missing chead references for a change required to ensure
# that obsolete changes are "known" by git and therefore don't get garbage
# collected. It doesn't exhaustively traverse the obsolescence graph, instead
# it stops at any commit that is already pinned assuming that anything
# reachable from it is also pinned.
pin_change() {
    pin_change_recursive $(get_change_id ${1}) ${1}
}
