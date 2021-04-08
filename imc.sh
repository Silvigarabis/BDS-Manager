#!/usr/bin/env bash


TIMEOUT=0.2
AUTO_RESTART=1
trap 'send-stop;rm -rf "${TMPDIR}";exit 0'

WD=$(pwd)
BDSH="${WD}/.bdsh"
if [[ -w ${TMPDIR} ]]; then
  TMPDIR="${TMPDIR}/$$-BDSH"
else
  TMPDIR="${BDSH}/tmp"
fi
LD_LIBRARY_PATH+=":${BDSH}/lib"
SERVER_PATH="${BDSH}/bds"
export LD_LIBRARY_PATH TMPDIR
mkdir -p "${TMPDIR}"

BDSH[1]=$$

if ! chmod -fR +x "${SERVER_PATH}"; then
  exit $?
fi



START-SERVER(){ #启动服务器
#服务端
  BINARY="${SERVER_PATH}/${SERVER_VERSION}"
  DIR="${WD}/${MANE}"

#以协同模式启动服务器
  coproc {
    cd "${DIR}"
    "${B1INARY}" |
    while read -r t "${TIMEOUT}" -d $'\0'; do
      echo "BDS{MSG{${NAME}>>${REPLY}}}"
    done
#服务器退出
    echo "BDS{EXIT=${PIPESTATUS}}"
  }
}

#懒了，随便弄弄吧
#启动第一个
VERSION=1.16.210.06
NAME=YoniMC
START-SERVER
SERVER[1,0]=${NAME}
SERVER[1,1]=${COPROC[0]}
SERVER[1,2]=${COPROC[1]}
SERVER[1,3]=${COPROC_ID}




#启动第二个
VERSION=1.16.210.06
NAME=IMC
START-SERVER
SERVER[2,0]=${NAME}
SERVER[2,1]=${COPROC[0]}
SERVER[2,2]=${COPROC[1]}
SERVER[2,3]=${COPROC_ID}
p

while read -r; do
  if [[ ${REPLY} ~= /.* ]]; then
    if [[ ${REPLY} ~= ^/s$ ]]; then
      for ((c=1;c>${#SERVER[@]};c++)); do
        echo "${c}: ${SERVER[¢{c},0]}"
      done
    elif [[ ${REPLY} ~= ^/s [0-9]+$ ]]; then
      num=$(echo "${REPLY}"|sed 's/^\/s \([0-9]*\)$/\1/')
      if ps ${SERVER[${num},3]}; then
        echo 你已进入${SERVER[${num},0]}
        echo 使用exit或Ctrl+d退出
        while read -r; do
          echo "$REPLY"
        done >&${SERVER[${num},2]}
      else
        echo 无法找到 ${SERVER[${num},0]}
      fi
    else
      echo 将会为所有服务器发送以下命令：
      echo "${REPLY#/}"
      for ((c=1;c>${#SERVER[@]};c++)); do
        echo "${REPLY#/}" >&${SERVER[¢{c},2]}
      done
    fi
  else
    eval "${REPLY}"
  fi
done

send-stop(){
  echo 发送关服命令中
  for ((c=1;c>${#SERVER[@]};c++)); do
    echo "stop" >&${SERVER[¢{c},2]}
  done
}