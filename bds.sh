config () {
    case "$1" in 
      read)shift 
        local line conf file="-" key value
        if [ -n "$1" ]; then 
            file="$1"
        fi 
        conf="$(
            (cat "${file}";echo) | while read line; do
                if [[ "$line" =~ ^#.*$ || "$line" =~ ^.+=.*$ ]]; then
                    echo "$line"
                fi 
            done 
        )"
        shift
        if [[ $# >0 ]]; then
            while(($#>0)); do
                key="$1";shift
                value+=`echo "${conf}"|grep "^${key}=.*$"`
            done 
            conf="$value"
        fi 
        echo -n "$conf"
    ;;
    "*")echo 不知道是什么，以后弄了再说 >&2
    ;;
    esac
}
version_list () {
#版本：列出
    local f c t l d 
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
} 
version_check () {
#版本：检查
    echo "[ 服务器 ] 从官网检查更新中"
    
    if [ -n "${latest_version}" ]; then
        latest="`basename -s .zip ${latest_version##*-}`"
        echo "${latest}" > "${conf}/latest"
        echo "${latest_version}" > "${conf}/latest_version"
        echo -e "[ 服务器 ] 最新的服务端版本为:\e[36m${latest}\e[0m"
        echo -e "[ 服务器 ] 下载链接:\e[36m${latest_version}\e[0m"
    else
        echo -e "[ 服务器 ] \e[31m无法获取最新版本\e[0m" >&2
        return $(wget -q -O - "https://www.minecraft.net/en-us/download/server/bedrock" &>/dev/null ; echo $?)
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
arg () {
if [ -n "$2" ]; then
    echo -e "出错:\e[31m$2\e[0m<<--此处"
fi
return "$1" &>/dev/null
}
:<<commandDescription
#命令解释器
#废了
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
commandDescription
:<<imc_last
#imc旧版
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
imc_last
:<<abd-6.0bds
#6.0 build时的bdsh
#以后处理
####################
#好看不？
#好看你赶紧写一个
#我快写疯了
#拜拜
#233333
####################
bds_path () {
#路径
    export bds_home=`pwd`
    export bds_storage="${bds_home}"/.bds
    export assets="${bds_storage}"/assets
    export server="${bds_home}"
    export bds_tmp="${bds_storage}"/tmp
    mkdir -p "${bds_home}" 
    mkdir -p "${bds_storage}"
    mkdir -p "${assets}"
    mkdir -p "${bds_tmp}"
    mkdir -p "${server}"
}
assets_update(){
#版本：检查
echo "[BDS:Version]尝试获取更新版本the
if wget -q -O "${bds_tmp}"/version.html https://www.minecraft.net/en-us/download/server/bedrock; then
    export latest=`grep -oe 'https://minecraft.azureedge.net/bin-linux/bedrock-server-.*.zip' "${bds_tmp}"/version.html`
    local word=${latest##*-}
    export latest=${word%.*}
    echo -e "[BDS:Version]最新版本:\e[36m${latest}\e[0m"
    echo -e "[BDS:Version]下载链接:\e[36mhttps://minecraft.azureedge.net/bin-linux/bedrock-server-${latest}.zip\e[0m"
else
    local state=$?
    echo -e "[BDS:Version]\e[31m无法获取最新版本\e[0m"
    exit ${state}
fi
}
assets_download(){
#版本：下载
local file success_times=0 err_times=0
while (($#>0)); do
    local ver="$1"; shift
    if wget -q --tries=1 --spider https://minecraft.azureedge.net/bin-linux/bedrock-server-"${ver}".zip; then
        if [ ! -f "${assets}"/bedrock-server-"${ver}".zip ]; then
            echo -e "[BDS:Assets]正在从官网下载(\e[33m${ver}\e[0m)"
            file="${bds_tmp}"/bedrock-server-"${ver}".zip
            wget https://minecraft.azureedge.net/bin-linux/bedrock-server-"${ver}".zip -O "${file}"
            mv -f "${file}" "${assets}"
            let success_times++
        else
            echo "[BDS:Assets]文件\"bedrock-server-${ver}.zip\"已存在"
            let err_times++
        fi
    else
        echo "[BDS:Download]无法找到\"${ver}\""
        let err_times++
    fi
done
echo -e "[BDS:Download]全部完成\n失败:${err_times}\n成功:${success_times}"
}
server_create(){
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
bds_shell () {
local cmd state path
echo 输入exit退出
while true; do
    echo -n "BDS;"
    path=`pwd`
    if [ "${state}" = 0 ]; then
        echo -e "\e[32m\c"
    else
        echo -e "\e[31m\c"
    fi
    echo -e "${state}\e[0m:\c"
    if [ "$path" = "$HOME" ]; then
        echo -n "~"
    elif [[ "$path" = *"$HOME"* ]]; then
        echo -n "~"
        echo -n "$path"|sed "s/$(echo "$HOME"|sed 's/\//\\\//g')//g"
    else
        echo -n "$path"
    fi
    echo -n " "
    read cmd
    if [ "${cmd}" != exit ]; then
        ${cmd}
        state=$?
    else
        echo 已退出BDS-SHELL
        exit ${state}
    fi
done
}
arg_err () {
    echo -e 出错:\\e[31m"$@"\\e[0m'<<'--此处
    exit 1
}
###############
#运行的部分
###############
:<<一会继续改
bds_home=`pwd`
if [ ! -d "${bds_home}"/.bds ]||[ ! -f "${bds_home}"/bds.txt ]; then 
    echo 你还没有进行初始化
    printf 输入bds进行初始化\ 
    read input
    if [ "$input" = bds ]; then
        bds_path
    else
        echo 已退出
        exit 1
    fi
fi
exit 0
一会继续改






#警告
if [ "$(whoami)" = root ]; then
    echo -e \\e[31m注意，你正在使用root用户运行此脚本\\e[0m
fi
#命令解释器
bds_path
command(){
case "$1" in
    -c)
        shift
        "$@"
    ;;
    --shell)
        bds_shell
    ;;
    assets)
        shift
        case "$1" in
            list)
                ls "$assets"
            ;;
            *)
                arg_err "$1"
            ;;
        esac
    ;;
    server)
        shift
        case "$1" in
            add)
                :
            ;;
            list)
                local list
                local count=0
                echo 即将列出服务器文件夹
                for list in `ls "${wd}"`; do
                    if [ -d "${wd}"/"${list}" ]; then
                        let count++
                        echo [${count}]: "${list}"
                    fi
                    
                done
                if [ ${count} = 0 ]; then
                    echo -e \\e[31m没有找到服务器文件夹
                    return 1
                else
                    return 0
                fi
            ;;
            remove)
                :
            ;;
            start)
                :
            ;;
            *)
                arg_err "$1"
            ;;
        esac
    ;;
    version|help|-h|--help|--version)
        help
    ;;
    "")
        echo 请输入参数
        help
        exit 128
    ;;
    *)
        arg_err "$1"
    ;;
esac
}
command "$@"
abd-6.0bds