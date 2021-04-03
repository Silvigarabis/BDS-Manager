#!/usr/bin/env bash
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

#start
START-SERVER(){ #启动服务器
#检查服务端
  BINARY="${SERVER_PATH}/${VERSION}"
  if [[ ! -f ${BINARY} ]]; then
    status=1
    return
  fi
#检查目录
  if [[ ! -d ${DIR} ]]; then
    status=2
    return
  fi
  cd "${DIR}"
  if [[ $? != 0 ]] ; then
    status=3
    return
  fi
#设置交换文件
  MSGSWAP="${TMPDIR}/${RANDOM}-SWAP-${NAME}"
  { #主进程
    { #读取输入文件
      {
        echo "MSG{PIPE{PROC0{$$}}}" >&3 #输出进程号
        tail -F "$INPUT" #读取
      } |
      { #服务器
        "${BINARY}" #服务端
        echo "MSG{MAIN-PROC{EXIT{$$}}}" #当服务端退出后输出状态
      } 2>&1
    } 3>&1 |
    { #处理输出
      echo "MSG{SWAP{RUNNING{\(.*\)}}}" #输出进程号
      while read li; do #读取一行
        if [[ ${li} ~= ^MSG\{.*\}$ ]]; then #如果为MSG
          if [[ -z ${INPUTPROC} ]]; then #如果未设置输入进程
            MSG=$(echo ${li}|sed -n 's/MSG{PIPE{PROC0{\(.*\)}}}/\1/') #获取数据
            if [[ -n $MSG ]]; then #如果数据获取成功
              INPUTPROC=$MSG #设置输入进程ID
              continue #再次进行
            fi
          fi
          MSG=$(echo ${li}|sed -n 's/MSG{MAIN-PROC{EXIT{\(.*\)}}}/\1/') #读取数据
          if [[ -n $MSG ]]; then #判定是否存在服务器退出数据
            break #停止读取
          fi
        else
          echo "MSG{$li}" #输出服务器信息
        fi
      done
      #服务器退出
      EXIT=$MSG
      kill ${INPUTPROC}
      echo "MSG{EXIT{STATUS{$EXIT}}}"
    } >"$MSGSWAP"
  } &
  #打开文件进行读取
  exec 3< "$MSGSWAP"
  for ((;;)); do #读取进程ID，读取到就结束
    MSG=$(cat | sed -n 's/MSG{SWAP{RUNNING{\(.*\)}}}/\1/')
    if [[ -n $MSG ]]; then
      PROC=($MSG)
      break
    else
      sleep 1s #未读取到，等待1秒
    fi
  done 0<&3
  ps $PROC &>/dev/null #检查进程
  if [[ $? != 0 ]]; then
    status=4
    return
  fi
  #设置服务器配置
  array=0
  for ((;;)); do
    if [[ -z ${SERVER[${array}]} ]]; then
      eval ${SERVER[${array,0}]}='"${NAME}"'
      eval ${SERVER[${array,1}]}='"${PROCS}"'
      eval ${SERVER[${array,2}]}='"${BINARY}"'
      eval ${SERVER[${array,3}]}='"${DIR}"'
      eval ${SERVER[${array,3}]}='"${VERSION}"'
      break
    fi
    let array++
  done
}.

imcst(){
    {
        echo 启动IMC
        : >"${i[0]}"
        : >"${std[0]}"
        : >"${str[0]}"
        cd "${WD}/IMC"
        tail -F "${i[0]}" | "${BDSH}/bds/1.16.210.06" >"${std[0]}" 2>"${str[0]}"
        echo "IMC关闭，时间：`date +%Y%m%d\ %H%M%S`；状态：$?" >"${str[0]}" 
        kill -40 ${main}
    } &
imc=$!
}

#主要的用来处理的
while read -r li; do
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
