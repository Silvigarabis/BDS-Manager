#!/bin/bash

WD="${PWD}"

bedrock_server(){(
  PATH=.
  exec bedrock_server
)}

main(){
  coproc bedrock_server
  
  while read -er; do
  done
}







get_latest_version(){
  if ! curl 'https://www.minecraft.net/en-us/download/server/bedrock'; then
    printf "[Update] Err: cannot download file from 'https://www.minecraft.net/en-us/download/server/bedrock'\n" >&2
  fi | sed -nE 's@.*bin-linux/bedrock-server-(.*)\.zip.*@\1@p'
}

eval "$@"
