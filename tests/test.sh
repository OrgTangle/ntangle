#!/usr/bin/env bash
# Time-stamp: <2018-10-03 15:52:35 kmodi>

set -euo pipefail # http://redsymbol.net/articles/unofficial-bash-strict-mode
IFS=$'\n\t'

repo_root="$(git rev-parse --show-toplevel)"

run_test () {
    bin="$1"
    "${bin}" tests/test1/test1.org tests/tangle_no_yes/tangle_no_yes.org # Test multiple Org files as arguments
    "${bin}" tests/src_blocks_with_extra_indentation/src_blocks_with_extra_indentation.org
    "${bin}" tests/multiple_src_blocks_tangled_to_same_file/multiple_src_blocks_tangled_to_same_file.org
    "${bin}" tests/wyag/write-yourself-a-git.org
    "${bin}" tests/shebang/shebang.org
    "${bin}" tests/missing_arg_value/missing_arg_value.org || true

    rm -rf ./tests/foo/bar/
    "${bin}" tests/mkdirp_no/mkdirp_no.org || true
    "${bin}" tests/mkdirp_yes/mkdirp_yes.org

    # Test tangling an Org file in the same dir.
    cd tests/tangle_mode || exit
    "../../${bin}" tangle_mode.org

    # "${bin}" tests/eless/eless.org
}

# Regular build
cd "${repo_root}"
nimble build -d:release
run_test "./ntangle"

# musl build
cd "${repo_root}"
nim musl src/ntangle.nim
run_test "./src/ntangle"
