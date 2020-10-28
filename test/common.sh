projectdir=$(cd $(dirname "$0")/.. && pwd)

# Common test initialization. Create a new git workspace and set it up
if [ -z "$TEST_TMP_DIR" ]
then
    if [ "$(readlink -f / 2>/dev/null)" != "/" ]
    then
        # Since this is a POC, I didn't want to deal with mktemp, readlink, tsort,
        # and potentially other incompatibilities.
        export PATH=/usr/local/opt/coreutils/libexec/gnubin:$PATH
        if [ "$(readlink -f / 2>/dev/null)" != "/" ]
        then
            echo >&2 "If you're on a mac, please install GNU coreutils."
            exit 1
        fi
    fi

    export TEST_TMP_DIR=$(mktemp -d -t obsolescence.XXXXXX)
    cd $TEST_TMP_DIR
    export TMPDIR=${TEST_TMP_DIR}

    mkdir -p remote
    pushd remote
    git init --bare
    rm -rf $(git rev-parse --git-dir )/hooks/*.sample
    popd

    git clone remote workspace
    pushd workspace
    git config obsolescence.enabled true
    rm -rf $(git rev-parse --git-dir )/hooks/*.sample

    script=$projectdir/test/$(basename "$0")
    # Re-exec the test script given the new repository setup
    PATH=${projectdir}/bin:$PATH exec $script ${1+"$@"}
else
    cleanup() {
        rm -rf $TEST_TMP_DIR
    }
    trap cleanup EXIT
    trap troubleshoot ERR
fi

export GIT_AUTHOR_NAME="Test Author"
export GIT_AUTHOR_EMAIL="author@example.com"
export GIT_COMMITTER_NAME="Test Committer"
export GIT_COMMITTER_EMAIL="committer@example.com"

. ${projectdir}/hooks/common.sh

list_predecessors() {
    local commit=$1
    git log -1 --pretty=%B $commit |
        git interpret-trailers --parse |
        awk '$1=="obsoletes:"{print$2}'
}

troubleshoot() {
    if [ -t 0 ]
    then
        echo >&2 "You're now in a troubleshooting shell, exit the shell to get back"
        # Tried calling $SHELL here but zsh has trouble if it is invoked more
        # than once from a script like this.
        bash --norc
    fi
}

fail() {
    echo ${1+"$@"}
    troubleshoot
    exit 1
}

assert_revs_equal() {
    local name=$1
    local expected=$2
    local actual=$3
    if [ "$(git rev-parse ${expected})" != "$(git rev-parse ${actual})" ]
    then
        fail "$name expected to be $expected but was $actual"
    fi
}

# This doesn't look like much but it fails under `set -e` when the sub-command
# succeeds. The `!` operator doesn't do this on its own.
not() {
    ! ${1+"$@"}
}

# ed_it makes it convenient to use `git rebase --interactive` non-interactively
# by supplying `ed` commands on stdin to edit the commit list. It writes the
# commands as a bash script to a temporary file and sets that script as EDITOR.
# This isn't perfect. For example, you can't use squash or anything that
# invokes an editor during the interactive rebase.
ed_it() {
    local script=$(mktemp -t ed.XXXXXX)
    cat >${script} <<-SCRIPT
	#!/bin/bash
	
	ed -s \$1 <<ED
	$(cat)
	ED
	SCRIPT
    chmod +x ${script}
    EDITOR=${script} ${1+"$@"}
}

# no_edit makes it convenient to use `git rebase --interactive`
# non-interactively to accept the default commit list without editing.
no_edit() {
    EDITOR=touch ${1+"$@"}
}

# This accelerates the pruning of unreachable objects in tests so that we can 
# be sure that old commits are available merely by accident. We want to be sure
# they continue to be available in the repository even when they are obsolete.
git_clean() {
    git reflog expire --expire=all --all
    git gc --prune=now --aggressive
}
