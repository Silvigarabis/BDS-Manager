#!/bin/bash
# check if programs are alive
set -e
type sha256sum
set +e

cd -P "$1"
CMWD=$(sed 's@/@\\/@g'<<EOF
${PWD}/
EOF
)
WD="${PWD}"
find "${WD}" -type f | 
  sed "s/^${CMWD}//g" |
  while read -r
  do
    sha=($(sha256sum < "${REPLY}"))
    echo $sha
  done
