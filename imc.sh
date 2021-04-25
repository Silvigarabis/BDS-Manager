WD="${PWD}"
BDSH="${WD}/.bds"
TMPDIR="${BDSH}/tmp"
mkdir -p "${BDSH}" "${TMPDIR}"
LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${BDSH}/lib"

#服务端
BDS_BIN="${BDSH}/libexec/bds/version"
(
  cd "${BDS_BIN}"
  chmod +x *
)

MAIN_PROC=$$

SERVER-START() {
  local BINARY="${BDS_BIN}/${VERSION}"
  local SERVER
  local SIGNAL
  local MAIN_PROC
  echo "启动“${SERVER}”"
  coproc {
    cd "${WD}/${SERVER}"
    "${BINARY}"
    echo "${SERVER}关闭，时间：`date +%Y%m%d\ %H%M%S`；状态：$?"
    kill -${SIGNAL} ${MAIN_PROC}
  }
}

s1() {
  local SERVER=IMC
  local VERSION=1.16.210.06
  local SIGNAL=40
  SERVER-START
  S1=(
    "${SERVER}"
    "${COPROC_PID}"
    "${COPROC[0]}"
    "${COPROC[1]}"
  )
  
}

s2() {
  local SERVER=YoniMC
  local VERSION=1.16.210.06
  local SIGNAL=40
  SERVER-START
  S2=(
    "${SERVER}"
    "${COPROC_PID}"
    "${COPROC[0]}"
    "${COPROC[1]}"
  )
}

s1
s2

STOP(){
  STOP=1
  echo "正在关闭服务器"
  echo stop >&${S1[3]}
  echo stop >&${S2[3]}
  wait ${S1[1]} ${S2[1]}
  echo "已关闭"
  kill -15 +${MAIN_PROC}
}

exec-cmd(){
  if [[ ! $EXEC ]]; then
    coproc bash
    {
      coproc {
        cat <&${COPROC[0]} >&5
      }
    } 5>&1
    EXEC=(
      "${COPROC_PID}"
      "${COPROC[0]}"
      "${COPROC[1]}"
    )
  elif ps ${EXEC[0]} &>/dev/null; then
    unset EXEC
    exec-cmd "$@"
  else
    echo "$@">&${EXEC[2]}
  fi
}

#主要的用来处理的
while read -r; do
  if [[ ${REPLY} =~ ^/?stop$ ]]; then
    stop
  elif [[ ${REPLY} =~ ^/s1\s.*$ ]]; then 
    echo "${REPLY#* }" >&${S1[3]}
  elif [[ ${REPLY} =~ ^/s2\s.*$ ]]; then 
    echo "${REPLY#* }" >&${S2[3]}
  elif [[ ${REPLY} = /s1 ]]; then
    printf "使用exit或\"Ctrl + d\"退出\n你当前进入的是${S1}的控制终端\n"
    while read -r; do
      if [[ ${REPLY} != exit ]]; then
        echo "${REPLY}"
      else
        break
      fi
    done >&${S1[3]}
    echo 已退出${S1}
  elif [[ ${REPLY} = /s2 ]]; then
    printf "使用exit或\"Ctrl + d\"退出\n你当前进入的是${S2}的控制终端\n"
    while read -r; do
      if [[ ${REPLY} != exit ]]; then
        echo "${REPLY}"
      else
        break
      fi
    done >&${S2[3]}
    echo 已退出${S2}
  elif [[ ${REPLY} =~ ^/.*$ ]]; then
    echo "${REPLY#*/}" >&${S1[3]}
    echo "${REPLY#*/}" >&${S2[3]}
  else
    exec-cmd "${REPLY}"
  fi
done

STOP
