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
