#警告
if [ "$(whoami)" = root ]; then
    echo -e "\e[31m注意，你正在使用root用户运行此脚本\e[0m"
fi
#路径及配置
config () {
    wd=`pwd`
    bds="${wd}/.bds"
    conf="${bds}/config"
    tmp="${bds}/tmp"
    assets="${bds}/assets"
    mkdir -p "${wd}" "${bds}" "${tmp}" "${conf}" "${assets}"
}
config
trap '[ -n "`ls -A ${tmp}`" ]&&rm -rf ${tmp}&&echo [ INFO ] 临时文件已清理; exit' 0 1 2
if [ -n "`ls -A ${conf}`" ]; then
    for i in "${conf}"/*; do
        eval ${i##*/}=`cat ${i}`
    done 
    unset i
fi
####################
version_list () {
#版本：列出
    local f c t l d 
    if [ $# = 0 ]; then
        if [ -n "`ls ${assets}`" ]; then
            echo "[ 服务器：版本 ] 当前已下载的版本"
            for f in "${assets}"/* ; do
                if [ -f "${f}" ]; then
                    let c++
                    echo "[${c}]: `basename -s .zip ${f}`"
                fi 
            done 
        else
            echo "[ 服务器：版本 ] 你还没有下载任何版本" >&2
        fi 
    elif [ "$1" = l ]; then 
        version_list >&2 &
        for f in "${assets}"/* ; do
            if [ -f "${f}" ]; then
                    t="${t} ${f}"
                    let c++
            fi 
        done 
        wait $!
        echo "l=($t)"
    else
        case $1 in 
        delete)eval `version_list l`
            if [ -z "${l}" ]; then 
                echo "没有可以删除的东西" >&2
                return 2
            else
                if [ -z "$2" ]; then
                    echo -n "请输入你要删除的版本或其编号 " 
                    read c 
                    if [ -f "${assets}/${c}.zip" ]; then 
                        d="${assets}/${c}.zip"
                    else
                        if [ -n "${c}" ]; then 
                            let c--
                            eval d=${l[${c}]}
                        fi 
                    fi
                else d="${assets}/$2.zip"
                fi 
                rm -f "${d}"
            fi
        ;;
        *)echo 未开发
        ;;
        esac
    fi
}
version_check () {
#版本：检查
    local status file="${tmp}/version_check.$$"
    echo "[ 服务器 ] 从官网检查更新中"
    if wget -q -O "${file}" "https://www.minecraft.net/en-us/download/server/bedrock"; then
        latest_version=`grep -oe 'https://minecraft.azureedge.net/bin-linux/bedrock-server-.*.zip' "${file}"`
        latest="`basename -s .zip ${latest_version##*-}`"
        echo "${latest}" > "${conf}/latest"
        echo "${latest_version}" > "${conf}/latest_version"
        echo -e "[ 服务器 ] 最新的服务端版本为:\e[36m${latest}\e[0m"
        echo -e "[ 服务器 ] 下载链接:\e[36m${latest_version}\e[0m"
    else
        status=$?
        echo -e "[ 服务器 ] \e[31m无法获取最新版本\e[0m" >&2
        (exit ${status})
    fi
}
version_download () {
#版本：下载
if [ $# != 0 ]; then
    local suc=0 err=0 link file ver status
    while (($#>0)); do
        ver="$1"; shift
        if [ "${ver}" = latest ]; then
            if [ -n "${latest}" ]; then 
                echo "[ 服务器：版本 ] 最新版本为${latest}，如有需要请使用命令检查更新"
                ver="${latest}"
            else
                echo "[ 服务器：版本 ] 获取最新版本ing"
                version_check
                if [ $? = 0 ]; then
                    ver="${latest}" 
                else
                    echo "[ 服务器：版本 ] 尝试获取最新版本时出错" >&2
                    ver="latest"
                fi
            fi
        fi
        if [ "${ver}" != latest ]&&echo -e "[ 服务器：下载 ] 尝试下载(\e[33m${ver}\e[0m)"&&wget -q --tries=1 --spider https://minecraft.azureedge.net/bin-linux/bedrock-server-"${ver}".zip; then
            if [ ! -f "${assets}/${ver}.zip" ]; then
                echo -e "[ 服务器 ] 正在从官网下载(\e[33m${ver}\e[0m)"
                file="${tmp}/${ver}.zip.$$"
                wget -O "${file}" https://minecraft.azureedge.net/bin-linux/bedrock-server-"${ver}".zip
                mv "${file}" "${assets}/${ver}.zip"
                let suc++
            else
                echo "[ 服务器：资源 ] 版本\"${ver}\"已存在" >&2
                let err++
            fi
        else
            echo "[ 服务器：下载 ] 无法找到\"${ver}\"" >&2
            let err++
        fi
    done
    echo -n "[ 服务器：下载 ] 全部完成"
    echo -n " 失败:${err}" >&2
    echo " 成功:${suc}"
else
    echo "[ 服务器：资源 ] 请指定至少一个版本" >&2
    return 1
fi
}
server_create () {
#创建服务器
if [ -z "$1" ]||(($#>2)); then
    bds_help server_create
    exit 128
fi
local ver state
if [ -n "$2" ]; then
    ver="$2"
    echo "[BDS:Server]服务器版本被指定为\"$2\""
else
    echo "[BDS:Server]未指定创建服务器的版本，默认使用最新版本"
    if [ -z "${latest}" ]; then
        echo "[BDS:Server]未检测到最新的版本，开始检查"
        assets_update
        state=$?
        if [ ${state} != 0 ]; then
            echo "[BDS:Server]出错，尝试指定一个版本"
            exit ${state}
        else
            assets_download "${latest}"
        fi
    else
        echo "[BDS:Server]最新版本为\"${latest}\""
    fi
    ver="${latest}"
fi
local server="${server}"/"$1" assets="${assets}/bedrock-server-${ver}.zip"
if [ ! -f ${assets} ]; then
    echo "[BDS:Server]版本\"${ver}\"不存在"
    exit 127
fi
if [ ! -e "${server}" ]; then
    echo "[BDS:Server]尝试创建\"$1\""
    mkdir -p "${server}"
    echo "[BDS:Unzip]解压${assets}"
    unzip -qd "${server}" "${assets}"
    state=$?
    if [ ${state} != 0 ]; then
        echo "[BDS:Unzip]解压出错"
        exit ${state}
    else
        echo "[BDS:Unzip]解压成功"
        echo "[BDS:Server]文件夹\"$1\"已创建"
    fi
else
    echo "[BDS:Server]文件\"$1\"已存在"
    exit 1
fi
}
bds_help(){
echo -e "BDS辅助v0.1\n"
if test -n "$1"; then
    case "$1" in
        server_create)cat<<endless
----创建一个服务器文件夹----
用法：server_create <名称> [版本]
endless
        ;;
        *)echo "$1未找到"
        ;;
    esac
fi
}

"$@"
exit
arg () {
if [ -n "$2" ]; then
    echo -e "出错:\e[31m$2\e[0m<<--此处"
fi
return "$1" &>/dev/null
}
###############
#运行的部分
###############
#命令解释器
case "$1" in
    version)shift
    case "$1" in
        list)count=0
        if [ -n "`ls -A ${version}`" ];then
            for assets in "${version}"/*; do
                if [ -f "${assets}" ]; then
                    let count++
                    list+="[${count}]: ${assets##*/}\n"
                fi
            done
        fi
        if [ -n "${list}" ]; then
            echo -e "当前已经下载的版本\n$list"
        else
            echo -e "\e[31m没有"
            arg 1
        fi;;
        check)version_check;;
        download)shift
        version_download "$@";;
        *)arg 2 "$1";;
    esac;;
    server)shift
    case "$1" in
        add)shift
        server_create "$@";;
        list)count=0
            echo 服务器文件夹
            sleep 1s
            for list in "${server}"/*; do
                if [ -d "${wd}"/"${list}" ]; then
                    let count++
                    echo [${count}]: "${list}"
                fi
            done
            if [ ${count} = 0 ]; then
                echo -e \\e[31m没有找到服务器文件夹
                exit 1
            fi;;
        remove);;
        start);;
        *)arg 2 "$1";;
    esac;;
    version)bds_help;;
    "")echo 请输入参数
    bds_help;;
    *)bds_help
    arg 2 "$1";;
esac






:<<yyyyyy
#这里的可以自由修改，当然，指定的版本必须存在
map=IMC
ver=1.16.201.02
###############
cmd () {
local c=`echo "$@"|sed -n '/^\/.*/p'`
if [ -n "$c" ]; then
    echo "${c#/}"
elif [ "$@" = stop ]; then
    exit
else
    eval "$@" >>cmd.txt
fi
}
wd=`pwd`
export LD_LIBRARY_PATH+=:"${wd}/lib"
bin="${wd}/bds_bin/${ver}"
wd="${wd}/server/${map}"
if [ -f "${bin}" ]; then
    mkdir "${wd}"
    cd "${wd}"
    chmod +x "${bin}"
    tail --retry -F cmd.txt &
    while read l ; do
        echo "[CMD] $ff" >>log.txt
        cmd "$l"
    done | "$bin" | while read f ; do
        echo "$f"
        echo "$f" >>log.txt
    done
else
    echo 所选择版本未找到
    exit 127
fi
yyyyyy