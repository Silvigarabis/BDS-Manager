#################
#################
#信号
trap 'echo "再见了"; rm -rf "${tmp}"; exit' 0 1 2
#################
#################
#变量
#启动路径
WD="$(pwd)"

#储存路径[0]:当前储存路径[1]:家储存路径
BDSH=("${WD}/.bds" "${HOME}/.bds")

#临时文件路径 如果有可读写的临时目录则使用
if [[ -r ${TMPDIR} && -w ${TMPDIR} ]]; then
    tmp="${TMPDIR}/bdsh.${$}-${RANDOM}"
else tmp="${BDSH}/tmp"
fi

#配置文件
CONFIG="${BDSH}/config"

#资源文件路径
ASSETS="${BDSH}/assets"

#脚本版本（从2021/2/17开始计算）
VERSION=`
    basename "${0}" |
    sed "s/\.(sh|rc)$//"
`" build 1"
#################
#################
#警告
if [[ ! ${BASH} ]]; then
    printf "\e[33m你可能没有使用BASH运行此脚本\e[0m\n" >&2
fi
#################
#################
#函数
#################
updateAssets_bedrockDedicatedServer () {
    ASSET_BEDROCK_DEDICATED_SERVER_LATEST_VERSION=`
        wget -qO - 'https://www.minecraft.net/en-us/download/server/bedrock'|
        grep -m 1 -oe 'bedrock-server-.*.zip'|
        sed -e 's/.*-//g' -e 's/\.zip//'
    `
    if [[ ! ${ASSET_BEDROCK_DEDICATED_SERVER_LATEST_VERSION} ]]; then
        printf "\e[33m获取最新版本时出错\e[0m\n"  
        return 1
    fi
}

#################
# 使用BDS作为控制变量
# 数组0：服务器列表
# 数组1：守护进程输入
# 数组2：守护进程
# 重新构造准备
bedrockDedicatedServer () { #服务器启动/关闭/发送命令/重启 等
    #启动守护进程
    if [[ ! ${BDS[2]} ]]; then
        bedrockDedicatedServerDaemon #服务器守护进程（等待中）
    fi
    #处理基础变量
    local option="$1" 
    local name="${2:-$$}"
    local pwd="${PWD}"
    case "${option}" in #判断操作
    start) #操作：启动服务器 设置变量 创建输入输出文件
        local directory="${3:-.}"
        local input="${tmp}/bds-input.${name}${RANDOM}"
        local output="${tmp}/bds-output.${name}${RANDOM}"
        local binary="${4:-${bds_latest_binary:-\$undefined}}"
        : > "${input}"
        : > "${output}"
        #启动服务器
        if [[ ${binary} = \$undefined ]]; then
            if [[ -f ${directory}/bedrock_server ]]; then #判断是否有可用服务端
                echo printf "\e[32mFound ./bedrock_server , try start it\e[0m"
                binary="${directory}/bedrock_server"
            else
                printf "\e[31mServer Binary File not found!\e[0m\n" >&2
                return 127
            fi
        fi
        #启动
        if cd "${directory}"; then
            tail -F "${input} | ${binary} > ${output}" &
            
            local process=$!
            cmd=`ps -hocmd "${process}"`
            server=("${name}" "${process}" "${directory}" "${input}" "${output}" "${binary}" "${cmd}")
            echo "server=(${server[@])" > "${BDSOINP}"
        else status=1
        fi
        cd "${pwd}"
        if [[ ${status} = 1 ]]; then 
            return 2
        fi
    stop) #操作：终止或暂停一个服务器
        local li e server
        while read li; do
            eval "${li}"
            if [[ ${e} = ${name} ]]; then
                server=(${e[@]})
                break
            fi
        done < 
        if [[ -z ${server} ]]; then
            echo 没有找到指定的服务器 >&2
            return 1
        fi
        local option="$2"
        case "${option}" in 
            continue)local signal=18
            forcestop)local signal=9
            forcestop=1
            pause)local signal=19
            ""|stop)local stop=1
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
bedrockDedicatedServerReadList () {
}
bedrockDedicatedServerDaemon () {
    BDSLIST="${tmp}/bds-list.$$-${RANDOM}" #列表文件
    while [[ -e ${BDS} ]]; do
        BDS="${tmp}/${FUNCNAME}_bds-list.$$-${RANDOM}.$$-${RANDOM}"
    done
    BDSDINP="${BDS}_deamon.inp" #输入文件
    BDSDOUT="${BDS}_deamon.out" #输出文件
    : > "${BDSDOUT}" && { tail -F "${BDSDOUT}" & } && BDSDOUT[2]=$!
    {
        trap "signal=0" 41
        trap "signal=1" 42
        for ((;;)); do
            echo "DAEMON_PROCESS=$$" > "${BDSDAEMON}"
            num=0
            unset list
            while read li; do #服务器列表文件转化为变量 获取列表内服务器状态
                list+="${li};"
                let num++
                eval "${li}"
                if ps ${server[1]}; then
                    status=1
                else status=0
                fi
                list[${num}]="server=(${server[@]} ${status})"
            done < "${BDSLIST}"
            num=0
            for ((i=0;i<${#server[@]};i++)); do
                let num++
                eval "${list[${num}]}"
                if [[ ${server[5]]} = 0 ]]; then
                    echo "名为“${server[1]]}”的服务器已关闭"
                else 
                    echo "名为“${server[1]]}”的服务器被关闭"
                fi
            done
        done
    } &>/dev/null &
    BDS[2]=$!
}
#################
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

#################
#################
#运行的部分
"$@"
