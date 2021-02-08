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
