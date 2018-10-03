#!/usr/bin/env bash
# Time-stamp: <2018-10-03 13:05:04 kmodi>

set -euo pipefail # http://redsymbol.net/articles/unofficial-bash-strict-mode
IFS=$'\n\t'

repo_root="$(git rev-parse --show-toplevel)"

run_test () {
    bin="$1"
    "${bin}" tests/test1.org
    "${bin}" tests/tangle_no_yes.org
    "${bin}" tests/src_blocks_with_extra_indentation.org
    "${bin}" tests/multiple_src_blocks_tangled_to_same_file.org
    "${bin}" tests/write-yourself-a-git.org
    "${bin}" tests/shebang.org
    "${bin}" tests/missing_arg_value.org || true

    rm -rf ./tests/foo/bar/
    "${bin}" tests/mkdirp_no.org || true
    "${bin}" tests/mkdirp_yes.org

    # Test tangling an Org file in the same dir.
    cd tests || exit
    "../${bin}" tangle_mode.org

    # "${bin}" tests/eless.org
}

cd "${repo_root}"
nimble build -d:release
run_test "./ntangle"

cd "${repo_root}"
nim musl src/ntangle.nim
run_test "./src/ntangle"
