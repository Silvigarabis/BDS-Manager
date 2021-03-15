# init
init(){
  cd "${wd:-$(pwd)}"
  wd=$(pwd)
  mkdir -p .bds .bds/version .bds/lib
  lib="${wd}/.bds/lib"
  version="${wd}/.bds/version"
}
log(){
  until [[ -w ${log} ]]; do
    log="${wd}/.bds/log/$(date).log"
    mkdir -p "$(dirname "${log}")"
    touch "${log}"
  done
  cat >"${log}"
}
# server functions
server(){

}
bds-assets-uncompress(){
  archive="$1"
  unzip -qo "${archive}"
  rm bedrock_server
  rm *.so
}
bds-server-create(){
  local name="$1"
  mkdir "${wd}/${name}" &>&1|log
  return $?
}
#get
get-bds-latest-version(){ BDS_LATEST_VERSION=$(wget -qO - 'https://www.minecraft.net/en-us/download/server/bedrock'|sed -n 's/.*bin-win\/bedrock-server-\(.*\).zip.*/\1/p'); }
#RUN
"$@"
