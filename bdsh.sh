#!/bin/bash
#cmd
trap 'echo 再见了; exit' 0 1 2
#Basic Value
WD="$(pwd)"
BDSH="${WD}/.bds"
TMP="${BDS}/tmp"
CONFIG="${BDS}/config"
VERSION="bdsh-8.0 build"
BDS_ASSETS="${BDS}/assets"
#Warn
if [[ "$(id -u)" = 0 ]]; then
    echo -e "\e[31m注意，你正在使用root用户运行此脚本\e[0m" >&2
fi
if [ ! "$BASH" ]; then
    echo -e "\e[33m你可能没有使用BASH运行此脚本\e[0m" >&2
fi
#################
#函数部分
#################
function imc() {
map=IMC
ver=1.16.200.02
log="${BDSH}/log/`date +%Y-%m-%d_%H:%M:%S`.txt"
mkdir -p "${WD}" "${BDSH}/log" "${TMP}"
LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${BDSH}/usr/lib"
PATH="${PATH}:${BDSH}/usr/bin"
bin="${BDSH}/bds/${ver}"
tail -F "${log}" 2>/dev/null &
if [ -f "${bin}" ]; then
    chmod +x "${bin}"
    while read line ; do
        if [[ -n $(echo ${line}|awk '/^[\/]?stop$/') ]]; then 
            echo 你可以在五秒内输入任意字符以取消 >&2
            read -t 5 cancel 
            if [ -z "${cancel}" ]; then
                echo stop 
                exit 
            else 
                echo 服务器将会继续运行 >&2
                unset cancel
            fi
        elif [[ "${line}" =~ ^/ ]]; then 
            echo "${line#/}" 
        else "$SHELL" -c "${line}" &>>"${log}"
        fi 
    done | (cd "${WD}/server/${map}";"${bin}") | while read li ; do 
        echo "[`date +'%Y-%m-%d %H:%M:%S'`]$li" 
    done
else 
    echo 指定的版本不存在 >&2
    (exit 127)
fi
}
##################
function update_bds() {
    BDS_LATEST_ASSET="$(wget -qO - 'https://www.minecraft.net/en-us/download/server/bedrock'|grep -oe 'https://minecraft.azureedge.net/bin-linux/bedrock-server-.*.zip')"
    BDS_LATEST_VERSION="$(echo ${BDS_LATEST_ASSET}|sed -e 's/.*-//g' -e 's/\.zip//')"
}
function config_map(){
    find "$WD" -maxdepth 2 -regex "$WD/[^.].*?/.bdsh_config" -type f | while read c; do
        cd $(basename "${c}")
    done
}
#################
#运行的部分
#################
"$@"
