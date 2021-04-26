WD="${PWD}"
BDSH="${WD}/.bds"
TMPDIR="${BDSH}/tmp"
mkdir -p "${BDSgit H}" "${TMPDIR}"
LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${BDSH}/lib"

#服务端
BDS_BIN="${BDSH}/libexec/bds/version"
(
  cd "${BDS_BIN}"
  chmod +x *
)

MAIN_PROC=$$

{
  coproc {
    cat >&5
  }
} 5>&1
OUTPUT=${COPROC[1]}

SERVER-START() {
  #set var 'SERVER' and 'SIGNAL' before use
  local BINARY="${BDS_BIN}/${VERSION}"
  echo "启动“${SERVER}”"
  coproc {
    cd "${WD}/${SERVER}"
    SERV_PROC=$$
    cat | {
      "${BINARY}"
      echo "${SERVER}关闭，时间：$(date +%Y%m%d\ %H%M%S)；状态：$?"
      kill -${SIGNAL} ${MAIN_PROC}
      kill -9 ${SERV_PROC}
    }
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
coproc {
  cat <&${S1[2]} |
    while read -r; do
      echo "${S1}:${REPLY}"
    done >&${OUTPUT}
}

s2
coproc {
  cat <&${S2[2]} |
    while read -r; do
      echo "${S2}:${REPLY}"
    done >&${OUTPUT}
}

STOP() {
  STOP=1
  echo "正在关闭服务器"
  echo stop >&${S1[3]}
  echo stop >&${S2[3]}
  wait ${S1[1]} ${S2[1]}
  echo "已关闭"
  kill -15 +${MAIN_PROC}
}

exec-cmd() {
  if [[ ! $EXEC ]]; then
    coproc bash
    EXEC=(
      "${COPROC_PID}"
      "${COPROC[0]}"
      "${COPROC[1]}"
    )
    {
      coproc {
        cat <&${EXEC[1]} >&5
      }
    } 5>&1
    exec-cmd "$@"
  elif ! ps ${EXEC[0]} &>/dev/null; then
    unset EXEC
    exec-cmd "$@"
  else
    echo "$@" >&${EXEC[2]}
  fi
}

#主要的用来处理的
while read -r; do
  if [[ ${REPLY} =~ ^/?stop$ ]]; then
    STOP
  elif [[ ${REPLY} =~ ^/s1\ .*$ ]]; then
    echo "${REPLY#*\ }" >&${S1[3]}
  elif [[ ${REPLY} =~ ^/s2\ .*$ ]]; then
    echo "${REPLY#*\ }" >&${S2[3]}
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
