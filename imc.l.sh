#!/bin/bash
WD="${PWD}"
BDS="${WD}/.bds/version"
coproc bash

start-servers(){
  while read -r; do
    eval "${REPLY}"
    cd "${WD}"
    cd "${SERVER[0]}"
    coproc "${BDS}/${SERVER[1]}"
    server[2]=${COPROC[0]}
    server[3]=${COPROC[1]}
    server[4]=${COPROC_ID}
    save-info
    
  done
}

save-info(){
  ((servers++))
  servers[${servers},1]="${server[0]}"
  servers[${servers},2]="${server[1]}"
  servers[${servers},3]="${server[2]}"
  servers[${servers},4]="${server[3]}"
  servers[${servers},5]="${server[4]}"
}

start-servers<<serverList
server=(IMC 1.16.210.06)
server=(YoniMC 1.16.210.06)
serverList

