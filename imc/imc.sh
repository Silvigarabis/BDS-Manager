init(){
  cd ${wd:-$(pwd)}
  wd=$(pwd)
  mkdir -p .bds .bds/tmp .bds/lib .bds/
  bds="${wd}./bds"
  tmp="${bds}/tmp"
  bindir="${bds}/bds"
  
  LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${bds}/lib"
  export LD_LIBRARY_PATH
}
initm
chmod -R +x "${bindir}"

create-fd(){
  local FDFILE
  (
    cd "${bds}"
    mkdir -p .fd
  )
  FDFILE="${bds}/.fd/$(date|base64).${RANDOM}"
  if [[ ! -e ${FDFILE} ]]; then
    touch "${FDFILE}"
    echo -n "${FDFILE}"
  else
    return 128
  fi
}

start-server(){
  local name="$1" dir="$2" ver="$3" input="$(create-fd)" output="$(create-fd)"
  echo "启动“${name}”"
  {
    cd "${WD}/IMC"
    { "${bindir}/${ver}" <"${input}" &>&1; server-stopped } | server-extra
  } &
  echo "bds=(server '${name}' '${dir}' '${ver}' '${input}' '${output}' '$!') >
}

server-extra(){
  while read li; do
    echo "bds={stop '${name}' '${li}')" >>"${output}"
  done
  
}
server-stopped(){
  status=$?
  time=$(date +%Y%m%d%H%M%S)
  echo "bds=(stop msg=\"[${time} ${name}]: 服务器关闭(状态：${status})\"">"${output}"
}

stop-all(){
    stop=1
    echo stop >>"${i[0]}"
    echo stop >>"${i[1]}"
    printf "正在关闭服务器\n"
    wait ${imc}
    wait ${yom}
    printf "已关闭\n"
    exit 0
}

tail -F "${std[0]}" | while read li; do
    echo "[IMC]:${li}"
done &
ot+="$! "
tail -F "${str[0]}" | while read li; do
    printf "\e[31m[IMC:2]\n"
    echo "${li}"
done &
ot+="$! "
tail -F "${std[1]}" | while read li; do
    echo "[YoniMC]:${li}"
done &
ot+="$! "
tail -F "${str[1]}" | while read li; do
    printf "\e[31m[YoniMC:2]\n"
    echo "${li}"
done &
ot+="$! "

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
