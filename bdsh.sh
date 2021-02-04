#!/bin/bash
#################
#################
#信号
trap 'echo "再见了"; rm -rf "${tmp}"; exit' 0 1 2
#################
#################
#变量
WD="$(pwd)"
BDSH="${WD}/.bds"
tmp="${BDS}/tmp"
CONFIG="${BDS}/config"
ASSETS="${BDS}/assets"
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
    local reboot=5 li server="bedrockDedicatedServer_old"
    #信号接收
    trap "echo '接收到崩溃信号';if ((reboot>1)); then echo '尝试重启服务器'; let reboot--; \${server}; else echo '多次重启失败，无法解决'; return; fi" 42
    trap "if [[ \${bds_stop} != 1 && \${auto_reboot} = 1 ]]; then echo '已启用自动重启'; \${server}; else exit; fi" 41
    ${server} #服务器运行
    while read -r li ; do
        if [[ ${li} =~ ^/?stop$ ]]; then 
            echo "你可以在五秒内输入任意字符并回车以取消"
            if (read -t 5 can; [[ -z ${can} ]]); then
                echo "stop" >"${cmd}"
                bds_stop=1
                wait ${bds_process}
            else 
                echo "服务器将会继续运行"
            fi
        elif [[ ${li} =~ ^/.*$ ]]; then 
            if [[ ${li} = / ]]; then
                echo 使用exit退出
                while read -r li; do
                    if [[ ${li} = exit ]]; then
                        echo 已退出
                        break
                    else echo "${li}" >"${cmd}"
                    fi
                done 
            else echo "${li#/}" >"${cmd}"
            fi
        else
            bash -c "${li}"
        fi
    done
    echo 正在关闭服务器
    echo "stop" >"${cmd}"
    wait ${bds_process}
}
bedrockDedicatedServer () { #服务器启动/关闭/发送命令/重启 等
    #启动守护进程
    if [[ ! ${BDS_DAEMON_PROCESS} ]]; then
        bedrockDedicatedServerDaemon #服务器守护进程（等待中）
    fi
    #处理基础变量
    local option="$1" 
    local name="${2:-$$}"
    local wd="${PWD}"
    case "${option}" in #判断操作
        start) #操作：启动服务器 设置变量 创建输入输出文件
        local directory="${3:-.}"
        local input="${tmp}/input.${name}${RANDOM}"
        local output="${tmp}/output.${name}${RANDOM}"
        local binary="${4:-${latest_binary:-\$undefined}}"
        mkdir -p "${cmd%/*}" "${out%/*}"
        : > "${input}"
        : > "${output}"
        cd "${directory}" #启动服务器
        if [[ ${binary} = \$undefined && ! -f ./bedrock_server ]]; then #判断是否有可用服务端
            printf "\e[31mServer Binary File not found!\e[0m\n"
            return 127
        else #启动
            tail -F "${input}" | "${binary}" > "${output}" &
            echo "('${name}' '$!' 'cmd=${input}' out='${output}')" > "${BDS_LIST}"
        fi;;
        stop) #操作：终止或暂停一个服务器
        local server=`grep -m 1 -oe "('${name}' '[0-9]*' '.*' '.*')" "${BDS_LIST}"`
        local option="$2"
        case "${option}" in 
            continue)local signal=18
            forcestop)local signal=9
            forcestop=1
            pause)local signal=19
            "")local stop=1
            *)return 1
            ;;
        esac
        if [[ ${stop} = 1 ]]; then
            bedrockDedicatedServer send stop "${server}"
        else 
            kill -${signal} ${server[2]}
        fi;;
    esac
}
bedrockDedicatedServerDaemon () {
}
bedrockDedicatedServer_old () {
    bds_main=$$
    cmd=.bdsh/cmd.$$
    : > "${cmd}"
    bedrockDedicatedServerProcess_old
}
bedrockDedicatedServerProcess_old () {
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
    if [[ ! ${ASSET_BEDROCK_DEDICATED_SERVER_LATEST} ]]; then
        printf "\e[33m获取最新版本时出错\e[0m\n"
        return 1
    fi
    ASSET_BEDROCK_DEDICATED_SERVER_LATEST_VERSION="$(echo ${ASSET_BEDROCK_DEDICATED_SERVER_LATEST}|sed -e 's/.*-//g' -e 's/\.zip//')"
}
config_map () {
    find "${WD}" -maxdepth 2 -regex "${WD}/[^.].*?/.bdsh_config" -type f | while read c; do
        cd $(basename "${c}")
    done
}
createServer_bedrockDedicatedServer () {
    local server="$1"
    local serverVersion="$2"
    if [[ -n ${server} ]]; then
        if [[ ! -e ${server} ]]; then
            printf "创建服务器${server}\n"
            if [[ -n ${serverVersion} ]]; then
                if [[ -f ${ASSETS}/bedrockDedicatedServer/${serverVersion} ]]; then
                    printf "版本: ${severVersion}\n"
                else
                    printf "\e[31m版本: ${serverVersion}不存在\e[0m\n"
                    return 1
                fi
            else
                printf "未指定版本，使用最新版本\n"
                if [[ ! ${ASSET_BEDROCK_DEDICATED_SERVER_LATEST_VERSION} ]]; then
                    printf "正在检查版本\n"
                    updateAssets_bedrockDedicatedServer
                fi
                serverVersion="${ASSET_BEDROCK_DEDICATED_SERVER_LATEST_VERSION}"
                printf "最新版本为${serverVersion}\n"
            fi
            mkdir "${server}"
            cd "${server}"
            printf "解压资源\n请确保有足够的空间"
            local c=0
            unzip -qo "${ASSETS}/bedrockDedicatedServer/${serverVersion}"
            if [[ $? != 0 ]]; then
                printf "解压出现错误，是否继续？[Y/n,默认为否]"
                c=1
            fi
            if [[ ${c} = 0 ]] || (read c; if [[ ${c} =~ ^[Y|y]$ ]]; then exit 0; else exit 1; fi); then
                mkdir .bdsh
                printf "#This is config for BDSH\n#Please don't modify it at will unless you know what it means.\ncreateVersion=${VERSION}\ntype=bedrockDedicatedServer\nserver=${server}\nserverVersion=${serverVersion}" >.bdsh/config
                mv bedrock_server .bdsh/setup
                printf "'${server}'创建完成\n版本: ${serverVersion}\n"
            else
                cd "${WD}"
                rm -rf "${server}"
                printf "取消创建\n" >&2
                return 2
            fi
        else 
            printf "无法创建，因为${server}已存在\n" >&2
            return 1
        fi
    else 
        echo "你需要为创建bedrockDedicatedServer指定一个名字" >&2
        echo "用法: $FUNCNAME <名字> [版本]" >&2
        echo "如不指定版本，默认使用 \${ASSET_BEDROCK_DEDICATED_SERVER_LATEST_VERSION} " >&2
        return 1
    fi
}
#################
#################
#运行的部分
"$@"
