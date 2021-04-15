#!/usr/bin/env bash
WD="${PWD}"

get-latest-version() {
  if [[ $# = 0 ]]; then
    wget -qO- 'https://www.minecraft.net/en-us/download/server/bedrock'
    if [[ $? != 0 ]]; then
      get-latest-version -v
    fi
  elif [[ $1 = --no-check-certificate ]]; then
    wget --no-check-certificate -qO- 'https://www.minecraft.net/en-us/download/server/bedrock'
  else
    wget -O- 'https://www.minecraft.net/en-us/download/server/bedrock' "$@"
  fi | sed -n 's/.*bin-linux\/bedrock-server-\(.*\).zip.*/\1/p'
}

"$@"
