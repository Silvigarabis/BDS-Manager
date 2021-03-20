#/bin/bash
. ./bds.sh
server-start IMC 1.16.210.06
server-start YoniMC 1.16.210.06

tail -F "${FD}" | while read -r li; do
    if [[ ${li} =~ ^/?stop$ ]]; then
        stop
    elif [[ ${li} =~ ^1/.*$ ]]; then 
        echo "${li#*/}" >>"${i[0]}"
    elif [[ ${li} =~ ^2/.*$ ]]; then 
        echo "${li#*/}" >>"${i[1]}"
    elif [[ ${li} = /1 ]]; then
        printf "使用exit或\"Ctrl + d\"退出\n你当前进入的是IMC的控制终端\n"
        while read -r li; do
            if [[ ${li} != exit ]]; then echo "${li}" >>"${i[0]}"
            else break
            fi
        done
        echo 已退出IMC
    elif [[ ${li} = /2 ]]; then
        printf "使用exit或\"Ctrl + d\"退出\n你当前进入的是YoniMC的控制终端\n"
        while read -r li; do
            if [[ ${li} != exit ]]; then echo "${li}" >>"${i[1]}"
            else break
            fi
        done
        echo 已退出YoniMC
    elif [[ ${li} =~ ^/.*$ ]]; then
        echo "${li#*/}" >>"${i[0]}"
        echo "${li#*/}" >>"${i[1]}"
    else bash -c "${li}"
    fi
done
stop

# init
init(){
  cd "${wd:-$(pwd)}"
  wd=$(pwd)
  mkdir -p .bds .bds/version .bds/lib
  lib="${wd}/.bds/lib"
  version="${wd}/.bds/version"
}
log(){
  until [[ -w ${log} ]]; do
    log="${wd}/.bds/log/$(date).log"
    mkdir -p "$(dirname "${log}")"
    touch "${log}"
  done
  cat >"${log}"
}
# server functions
server(){

}
bds-assets-uncompress(){
  archive="$1"
  unzip -qo "${archive}"
  rm bedrock_server
  rm *.so
}
bds-server-create(){
  local name="$1"
  mkdir "${wd}/${name}" &>&1|log
  return $?
}
#get
get-bds-latest-version(){ BDS_LATEST_VERSION=$(wget -qO - 'https://www.minecraft.net/en-us/download/server/bedrock'|sed -n 's/.*bin-win\/bedrock-server-\(.*\).zip.*/\1/p'); }
#RUN
"$@"
