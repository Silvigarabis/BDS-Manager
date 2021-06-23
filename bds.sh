#!/bin/bash

ORIGIN=${ORIGIN:-$(cat "$0")}
WD=${WD:-${PWD}}

get-latest-version() {
  local update_file=$(curl 'https://www.minecraft.net/en-us/download/server/bedrock')
  sed -nE 's@.*bin-linux/bedrock-server-(.*)\.zip.*@\1@p' <<EOF
${update_file}
EOF
}

"$@"

