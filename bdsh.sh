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
    local map=IMC
    local ver=1.16.200.02
    local LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${BDSH}/usr/lib"
    local PATH="${PATH}:${BDSH}/usr/bin"
    local bin="${BDSH}/bds/${ver}"
    mkdir -p "${WD}" "${BDSH}/log" "${TMP}"
    cd "${WD}/server/${map}"
    mkdir -p .bdsh
    if [[ -f ${bin} ]]; then
        if [[ ! -x ${bin} ]]; then
            if ! chmod +x "${bin}"; then
                local status=$?
                echo 出现未知错误
                return ${status}
            fi
        fi
    else
        echo 未找到指定的版本
        return 127
    fi
    local reboot=5 li
    echo $$
    trap "echo 接收到崩溃信号;if ((reboot>1)); then echo 尝试重启服务器; let reboot--; bedrock_dedicated_server; else echo 多次重启失败，无法解决; return; fi" 42
    trap "kill -2 \${bds_process}" 2
    trap "kill -15 \${bds_process}" 15
    trap "if [[ \${bds_stop} != 1 && \${auto_reboot} = 1 ]]; then echo 已启用自动重启; bedrock_dedicated_server; else exit; fi" 41
    bedrock_dedicated_server
    while read li ; do
        if [[ ${li} =~ ^/?stop$ ]]; then 
            echo 你可以在五秒内输入任意字符并回车以取消
            if (read -t 5 can; [[ -z ${can} ]]); then
                echo stop >"${cmd}"
                bds_stop=1
                wait ${bds_process}
            else 
                echo 服务器将会继续运行
            fi
        elif [[ "${li}" =~ ^/.*$ ]]; then 
            echo "${li#/}" >"${cmd}"
        else
            "${SHELL}" -c "${li}"
        fi 
    done
}
function bedrock_dedicated_server()
{
    bds_main=$$
    cmd=.bdsh/cmd.$$
    : > "${cmd}"
    bedrock_dedicated_server_main
    bds_process=$!
}
function bedrock_dedicated_server_main(){
#服务器进程
    tail -F "${cmd}" 2>/dev/null | {
        "${bin}"
        if [ $? = 0 ]; then
            echo 服务器已关闭
            kill -41 ${bds_main}
        else
            echo 服务器崩溃
            kill -42 ${bds_main}
        fi
    } &
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
