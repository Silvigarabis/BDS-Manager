#!/bin/bash
#################
#################
#信号
trap "echo '再见了'; exit" 0 1 2
#################
#################
#变量
WD="$(pwd)"
BDSH="${WD}/.bds"
TMP="${BDS}/tmp"
CONFIG="${BDS}/config"
VERSION="bdsh-8.0 build"
BDS_ASSETS="${BDS}/assets"
#################
#################
#警告
if [[ $(id -u) = 0 ]]; then
    printf "\e[31m注意，你正在使用root用户运行此脚本\e[0m\n" >&2
fi
if [[ ! ${BASH} ]]; then
    printf "\e[33m你可能没有使用BASH运行此脚本\e[0m\n" >&2
fi
#################
#################
#函数
imc () { #此函数专为Imeaces-Minecraft-Bedrock-Server设计
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
                echo "出现未知错误" >&2
                return ${status}
            fi
        fi
    else
        echo "未找到指定的版本" >&2
        return 127
    fi
    local reboot=5 li server="bedrockDedicatedServer"
    #信号接收
    trap "echo '接收到崩溃信号';if ((reboot>1)); then echo '尝试重启服务器'; let reboot--; \${server}; else echo '多次重启失败，无法解决'; return; fi" 42
    trap "if [[ \${bds_stop} != 1 && \${auto_reboot} = 1 ]]; then echo '已启用自动重启'; \${server}; else exit; fi" 41
    ${server} #服务器运行
    while read li ; do
        if [[ ${li} =~ ^/?stop$ ]]; then 
            echo "你可以在五秒内输入任意字符并回车以取消"
            if (read -t 5 can; [[ -z ${can} ]]); then
                echo "stop" >"${cmd}"
                bds_stop=1
                wait ${bds_process}
            else 
                echo "服务器将会继续运行"
            fi
        elif [[ "${li}" =~ ^/.*$ ]]; then 
            echo "${li#/}" >"${cmd}"
        else
            bash -c "${li}"
        fi 
    done
}
bedrockDedicatedServer () {
    bds_main=$$
    cmd=.bdsh/cmd.$$
    : > "${cmd}"
    bedrockDedicatedServerProcess
}
bedrockDedicatedServerProcess () {
#服务器进程
    tail -F "${cmd}" 2>/dev/null | {
        "${bin}"
        if [ $? = 0 ]; then
            echo "服务器已关闭"
            kill -41 ${bds_main}
        else
            echo "服务器崩溃" >&2
            kill -42 ${bds_main}
        fi
        return 42
    } &
    bds_process=$!
}
##################
updateAssets_bedrockDedicatedServer () {
    ASSET_BEDROCK_DEDICATED_SERVER_LATEST="$(wget -qO - 'https://www.minecraft.net/en-us/download/server/bedrock'|grep -oe 'https://minecraft.azureedge.net/bin-linux/bedrock-server-.*.zip')"
    ASSET_BEDROCK_DEDICATED_SERVER_LATEST_VERSION="$(echo ${BDS_LATEST_ASSET}|sed -e 's/.*-//g' -e 's/\.zip//')"
}
config_map () {
    find "$WD" -maxdepth 2 -regex "$WD/[^.].*?/.bdsh_config" -type f | while read c; do
        cd $(basename "${c}")
    done
}
#################
#################
#运行的部分
"$@"
