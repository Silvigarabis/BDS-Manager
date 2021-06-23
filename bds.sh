#!/bin/bash

ORIGIN=${ORIGIN:-$(cat "$0")}
WD=${WD:-${PWD}}

get-latest-version() {
  if ! curl 'https://www.minecraft.net/en-us/download/server/bedrock'; then
    printf "Err: cannot download file from 'https://www.minecraft.net/en-us/download/server/bedrock'\n" >&2
  fi | sed -nE 's@.*bin-linux/bedrock-server-(.*)\.zip.*@\1@p'
}

"$@"
