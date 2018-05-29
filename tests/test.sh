#!/usr/bin/env bash
# Time-stamp: <2018-05-29 15:36:44 kmodi>

cd ..
nimble build -d:release
./ntangle tests/test1.org
./ntangle tests/tangle_no_yes.org
./ntangle tests/src_blocks_with_extra_indentation.org
./ntangle tests/multiple_src_blocks_tangled_to_same_file.org
./ntangle tests/write-yourself-a-git.org
./ntangle tests/shebang.org
./ntangle tests/missing_arg_value.org || true

rm -rf ./tests/foo/bar/
./ntangle tests/mkdirp_no.org || true
./ntangle tests/mkdirp_yes.org

./ntangle tests/tangle_mode.org

# ./ntangle tests/eless.org
