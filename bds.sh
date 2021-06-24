#!/bin/bash

ORIGIN=${ORIGIN:-$(cat "$0")}
WD=${WD:-${PWD}}

getLatestVersion(){
  if ! curl 'https://www.minecraft.net/en-us/download/server/bedrock'; then
    printf "Err: cannot download file from 'https://www.minecraft.net/en-us/download/server/bedrock'\n" >&2
  fi | sed -nE 's@.*bin-linux/bedrock-server-(.*)\.zip.*@\1@p'
}

version(){
  case "$1" in
  
}
"$@"
