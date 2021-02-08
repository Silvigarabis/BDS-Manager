updateAssets_bedrockDedicatedServer () {
    ASSET_BEDROCK_DEDICATED_SERVER_LATEST="$(wget -qO - 'https://www.minecraft.net/en-us/download/server/bedrock'|grep -oe 'https://minecraft.azureedge.net/bin-linux/bedrock-server-.*.zip')"
    if [[ ! ${ASSET_BEDROCK_DEDICATED_SERVER_LATEST} ]]; then
        printf "\e[33m获取最新版本时出错\e[0m\n"
        return 1
    fi
    ASSET_BEDROCK_DEDICATED_SERVER_LATEST_VERSION="$(echo ${ASSET_BEDROCK_DEDICATED_SERVER_LATEST}|sed -e 's/.*-//g' -e 's/\.zip//')"
}
