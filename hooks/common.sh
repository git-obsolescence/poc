# verify_commit prints the sha1 of a valid commit and exits with 0. If the
# commit is not valid in the current repository, it exits non-zero
verify_commit() {
    # git rev-parse only verifies that the ref derefenences to a valid sha1.
    # It doesn't check that the commit is valid in the current repository.
    # git rev-parse --quiet --verify $commit

    git log -1 --pretty=%H $1 2>/dev/null
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

    first_edge=$(git log -1 --pretty=%B $commit |
        git interpret-trailers --parse |
        awk '$1=="obsoletes:"{print$2;exit}')

    if [ -z "$first_edge" ]
    then
        verify_commit $commit
        return
    fi

    if verify_commit ${commit}~ >/dev/null
    then
        first_parent_edge=$(git log -1 --pretty=%B ${commit}~ |
            git interpret-trailers --parse |
            awk '$1=="obsoletes:"{print$2;exit}')
        if [ "$first_edge" = "${first_parent_edge}" ]
        then
            verify_commit $commit
            return
        fi
    fi

    get_change_id ${first_edge}
}
