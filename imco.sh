WD="$(pwd)"
BDSH="${WD}/bds"
if [[ -r ${TMPDIR} && -w ${TMPDIR} ]]; then
    tmp="${TMPDIR}/bdsh.${$}-${RANDOM}"
else tmp="${BDSH}/tmp"
fi
mkdir -p "${tmp}"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${BDSH}/usr/lib"

#服务端
bin="${BDSH}/bds/1.16.210.06"
if [[ -f ${bin} ]]; then
    if [[ ! -x ${bin} ]]; then
        if ! chmod +x "${bin}"; then
            local status=$?
            echo "出现未知错误" >&2
            exit ${status}
        fi
    fi
else
    echo "未找到指定的版本" >&2
    exit 127
fi

#设置输入输出
i=("${tmp}/${RANDOM}.1" "${tmp}/${RANDOM}.4")
std=("${tmp}/${RANDOM}.2" "${tmp}/${RANDOM}.5")
str=("${tmp}/${RANDOM}.3" "${tmp}/${RANDOM}.6")


#start
main=$$
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
yomst(){
    {
        echo 启动YoniMC
        : >"${i[1]}"
        : >"${std[1]}"
        : >"${str[1]}"
        cd "${WD}/YoniMC"
        tail -F "${i[1]}" | "${bin}" >"${std[1]}" 2>"${str[1]}"
        echo "YoniMC关闭，时间：`date +%Y%m%d\ %H%M%S`；状态：$?" >"${str[1]}"
        kill -41 ${main}
    } &
yom=$!
}
imcst 
yomst 

trap "if [[ \${stop} != 1 ]]; then imcst; fi" 40
trap "if [[ \${stop} != 1 ]]; then yomst; fi" 41

stop(){
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
