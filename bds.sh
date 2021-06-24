#!/bin/bash

# this script does not set to readable

ORIGIN=${ORIGIN:-$(cat "$0")}
WD=${WD:-${PWD}}

get_latest_version(){
  if ! curl 'https://www.minecraft.net/en-us/download/server/bedrock'; then
    printf "[Update] Err: cannot download file from 'https://www.minecraft.net/en-us/download/server/bedrock'\n" >&2
  fi | sed -nE 's@.*bin-linux/bedrock-server-(.*)\.zip.*@\1@p'
}

version(){
  case "$1" in
    check-update)
      printf "[Update] Download Version Document File\n" >&2
      {
        get_latest_version
      }
    ;;
  esac
}

server_start(){
# start server that setuped in correct path
  local bds_config="$(awk '/^($|[A-Za-z_]([A-Za-z0-9_]*)?=.*|#.*)/' .bds_config)"
  local server_name="$(
    { sed -nE 's/name=(.*)/\1/gp' | tail -n 1; } <<EOF
${bds_config}
EOF
  )"
  local server_type="$(
    { sed -nE 's/type=(.*)/\1/g;s/\x20/_/gp' | tail -n 1; } <<EOF
${bds_config}
EOF
  )"
  "server_type_${server_type}"
}

server_type_bedrock_dedicated(){
  ls
}
# Imeaces@guxi:~$ cat /server/IMC/start.sh
# #!/bin/bash
# if [ -f server-info.properties ]; then
  # while read -r; do
    # eval "$REPLY"
  # done<<EOM
# `awk '/^($|[A-Za-z_]([A-Za-z0-9_]*)?=.*|#.*)/' server-info.properties`
# EOM
# fi
# if [ -n "$start" ]; then
  # eval "$start"
# else
  # printf "start command not found!\n"
  # exit 1
# fi
# Imeaces@guxi:~$ cat /server/IMC/server-info.properties
# #comment
# name=IMC
# server-version=(1 17 0)
# type=(bedrock dedicated)
# port=(40233)
# version=1.17.0
# bin="bedrock_server-${version}"
# jebwkqn2n2n2kldo
# start=./bedrock_server
# 
# Imeaces@guxi:~$
eval "$@"

