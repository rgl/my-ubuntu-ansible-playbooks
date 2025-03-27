#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/git-filter-repo ]; then
    # e.g. 2.27.0
    actual_version="$(/usr/local/bin/git-filter-repo --version | perl -ne '/(\d+(\.\d+)+)/ && print $1')"
    if [ "$actual_version" == "$GIT_FILTER_REPO_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
url="https://github.com/newren/git-filter-repo/releases/download/v${GIT_FILTER_REPO_VERSION}/git-filter-repo-${GIT_FILTER_REPO_VERSION}.tar.xz"
t="$(mktemp -q -d --suffix=.git-filter-repo)"
wget -qO- "$url" | tar xJ -C "$t" --strip-components 1
# patch the source to make it return the version.
# NB this will not be required after https://github.com/newren/git-filter-repo/issues/653 is fixed.
perl -i -pe '
    BEGIN {
        $found = 0;
    }
    if (/^(\s*)def print_my_version\(\):$/) {
        $_ .= "$1$1print(\"$ENV{GIT_FILTER_REPO_VERSION}\");return\n";
        $found = 1;
    }
    END {
        die "failed to patch source code\n" unless $found;
    }' \
    "$t/git-filter-repo"
install -m 755 "$t/git-filter-repo" /usr/local/bin/git-filter-repo
rm -rf "$t"

# give it a try.
/usr/local/bin/git-filter-repo --version
