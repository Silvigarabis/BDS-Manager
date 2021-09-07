#!/bin/bash
set -e
unset sha256List
find . -type f -exec sha256sum {} \; | 
  {
    rm sha256 || true
    while read -er; do
      sha256=${REPLY%%\ *}
      file="${REPLY:68:${#REPLY}}"
      sha256List+="${sha256} ${file}"$'\n'
    done
    echo "$sha256List" >sha256
  }
