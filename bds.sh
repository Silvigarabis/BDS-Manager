#!/bin/bash

set -n

SCRIPT_ORIGIN=$(cat `realpath "$0"`)
WD=$(pwd)
DIR_BDS="${wd}./bds"
DIR_BIN_BDS="${DIR_BDS}/bds"
TMPDIR="${bds}/tmp"

LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${bds}/lib"
export LD_LIBRARY_PATH

mkdir -p .bds .bds/tmp .bds/lib .bds

fd-create(){
  (
    mkdir -p "${DIR_BDS}/fd"
    cd "${DIR_BDS}/fd"
    fd="$(date|base64).${RANDOM}"
    printf >"${fd}"
    realpath -e "${fd}"
  )
}
FD=$(fd-create)
trap 'status=$?; rm "${FD}"; exit ${status};'
#由于方便的原因，决定只用一个文件作为输入输出交换
#在长期运行的服务器可能会出现问题
#以后解决
#设想，定期清空文件，防止文件过大
# continue

server-start(){
  local name="$1" ver="$2"
  local id=$(printf "$(printf "${name}"|base64);${FD};$(date)"|sha256sum)
  echo "启动“${name}”"
  bds-server
}

bds-server()  {
  cd "${WD}/${name}"
  local bin="${DIR_BIN_BDS}/${ver}"
  bds-server-main &
  server-bds-info "${fd}" "${id}" "${name}" "${ver}" "$!"
}
server-bds-info(){
  fd="$1"
  id="$2"
  name="$3"
  ver="$4"
  proc="$5"
  echo "bds{server{type:info,id:${id}},name:${name},ver:${ver},proc:${proc}}" >>"${fd}"
}
bds-server-main(){
    bds-server-read-cmd | {
      "${bin}" 2>&1
      bds-server-exit
    } | bds-server-extra
}
bds-server-read-cmd(){
  fd-read xml "${fd}" "bds" "server" "${id}" "input"
}
bds-server-extra(){
  local time
  while read li; do
    time=$(date)
    if [[ ${li} ~= ^<bds><server><exit>.*</exit></server></bds>$ ]]; then
      local exit=$(printf "${li}" | fd-read "-" "xml" "bds" "server" "exit" "status")
      bds-server-stop-msg "${FD}" "${name}" "${exit}" "${time}"
      break
    else
      bds-server-msg "${FD}" "${name}" "${ver}" "${time}" "${li}"
    fi
  done
}

fd-read(){
  file="$1"
  type="$2"
  FILE=$(cat "${file}")
  
  case "${type}" in
  xml)
    shift
    f-xml-read "$@"
  ;;
  esac
}
f-xml-read(){
  
  echo "${FILE}" | while read li; do
    while(($#>0)); do
      FILEecho "${li}" | sed -n "s/$1\{\(.*\)\}/\1/p"
      
}
bds-server-stop-msg(){
  fd="$1"
  server="$2"
  status="$3"
  time="$4"
  echo "{bds=stop;server=${server};[${time} ${name}]: 服务器关闭(状态：${status}/bds}" >>"${fd}"
}
####################
#这是一个非常离谱的部分
#隶属于编写者/团队的服务器
#因为bds.sh还没写完
