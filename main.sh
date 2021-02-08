#################
#################
#信号
trap 'echo "再见了"; rm -rf "${tmp}"; exit' 0 1 2
#################
#################
#变量
WD="$(pwd)"
BDSH="${WD}/.bds"
if [[ -r ${TMPDIR} && -w ${TMPDIR} ]]; then
    tmp="${TMPDIR}/bdsh.${$}-${RANDOM}"
else tmp="${BDS}/tmp"
fi
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
bedrockDedicatedServerDaemon () {
    BDS_LIST="${tmp}"
}
##################
config_map () {
    find "${WD}" -maxdepth 2 -regex "${WD}/[^.].*?/.bdsh_config" -type f | while read c; do
        cd $(basename "${c}")
    done
}
#################
#################
#运行的部分
"$@"
