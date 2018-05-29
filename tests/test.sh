#!/usr/bin/env bash
# Time-stamp: <2018-05-29 12:11:29 kmodi>

cd ..
nimble build -d:release
./ntangle tests/test1.org
./ntangle tests/tangle_no_yes.org
./ntangle tests/src_blocks_with_extra_indentation.org
./ntangle tests/multiple_src_blocks_tangled_to_same_file.org
./ntangle tests/write-yourself-a-git.org
./ntangle tests/eless.org
