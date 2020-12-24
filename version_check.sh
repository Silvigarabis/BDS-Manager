. ./base.sh
version_check () {
#版本：检查
local state=0
echo "[Version]尝试获取更新版本"
if wget -q -O "${tmp}/version" "https://www.minecraft.net/en-us/download/server/bedrock"; then
    export latest_version=`grep -oe 'https://minecraft.azureedge.net/bin-linux/bedrock-server-.*.zip' "${tmp}/version"`
    export latest="${latest_version##*-}"
    latest="${latest%.*}"
    echo "${latest}" > "${bds}/config"
    echo "${latest_version}" > "${prop}/latest_version"
    echo -e "[Version]最新版本:\e[36m${latest}\e[0m"
    echo -e "[Version]下载链接:\e[36m${latest_version}\e[0m"
else
    state=$?
    echo -e "[Version]\e[31m无法获取最新版本\e[0m" >&2
    return ${state}
fi
}
version_check