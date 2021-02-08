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
            printf "\e[31mServer Binary File not found!\e[0m\n" >&2
            return 127
        else #启动
            tail -F "${input}" | "${binary}" > "${output}" &
            echo "('${name}' '$!' 'cmd=${input}' out='${output}')" > "${BDS_LIST}"
        fi;;
        stop) #操作：终止或暂停一个服务器
        local li e server
        while read li; do
            e=${li}
            if [[ ${e} = ${name} ]]; then
                server=(${e[@]})
                break
            fi
        done < "${BDS_LIST}"
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