#!/usr/bin/env bash
# Usage: ./quick_test.sh

owner="OrgTangle"
repo="ntangle"
latest_release_url="$(curl -s "https://api.github.com/repos/${owner}/${repo}/releases/latest" | grep 'browser_download_url.*\.xz' | cut -d: -f2,3 | sed 's/[" ]//g')"
archive_name="$(echo "${latest_release_url}" | rev | cut -d/ -f1 | rev)"
temp_dir="/tmp/${USER}/${repo}/quick"
test="tangle_no_yes"

if [[ -d "${temp_dir}" ]]
then
    rm -rf "${temp_dir}"
fi
mkdir -p "${temp_dir}"

cd "${temp_dir}" || exit
ls -la

echo ""
echo "Downloading ${latest_release_url} .."
wget -nd "${latest_release_url}"
tar xf "${archive_name}"

echo ""
echo "Downloading test ${test} .."
wget -nd "https://raw.githubusercontent.com/${owner}/${repo}/master/tests/${test}/${test}.org"

echo ""
cmd="./${repo} ${test}.org"
echo "Running ${cmd} .."
eval "${cmd}"

echo ""
ls -la
