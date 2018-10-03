#!/usr/bin/env bash
# Usage: ./quick_test.sh

version="v0.2.1"
temp_dir="/tmp/${USER}/ntangle/quick"
test="tangle_no_yes"

if [[ -d "${temp_dir}" ]]
then
    rm -rf "${temp_dir}"
fi
mkdir -p "${temp_dir}"

cd "${temp_dir}" || exit
ls -la

echo ""

echo "Downloading ntangle ${version} .."
wget -nd https://github.com/OrgTangle/ntangle/releases/download/"${version}"/ntangle-"${version}".Linux_64bit_musl.tar.xz
tar xf ntangle-"${version}".Linux_64bit_musl.tar.xz

echo ""
echo "Downloading test ${test} .."
wget -nd "https://raw.githubusercontent.com/OrgTangle/ntangle/master/tests/${test}/${test}.org"

echo ""
cmd="./ntangle ${test}.org"
echo "Running ${cmd} .."
eval "${cmd}"

echo ""
ls -la
