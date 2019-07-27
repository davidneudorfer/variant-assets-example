#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
[[ "${DEBUG:=false}" == 'true' ]] && set -o xtrace

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly NC='\033[0m' # No Color

readonly NODE_VERSION='12.6-stretch'
readonly GOLANG_VERSION='1.12.6'
readonly GODEB_VERSION='0.5.4'
readonly GOOS='darwin'
readonly GOARCH='amd64'
readonly CLI_NAME='apl'
readonly REPO_SITE='github.com'
readonly REPO_OWNER="davidvasandani"
readonly REPO_SLUG="cli"
readonly REPO_PATH="/go/src/${REPO_SITE}/${REPO_OWNER}/${REPO_SLUG}/"

_cleanup() {
  pkill -9 -f "scripts/build-cli.sh"
  rm -rf tmp.*
}

TMPDIR=$(pwd)
export TMPDIR
readonly _TMPDIR=$(_cleanup && mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXX")

err() {
  if [[ "${RUN_BY_CRON:=false}" == 'true' ]]; then
    echo "$*"
  else
    echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
  fi
}
log() {
  if [[ "${RUN_BY_CRON:=false}" == 'true' ]]; then
    echo "$*"
  else
    echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
  fi
}

# trap _destroy EXIT ERR

_destroy() {
  if [[ $? == 0 ]]; then
    rm -rf "${_TMPDIR}"
  else
    et=$(date +%s)
    log "${RED}Total Elasped: $((et - st)) seconds${NC}"
  fi
}

_variant() {
echo ${_TMPDIR}
variant build cli > "${_TMPDIR}/variant-cli-ouput-file"
cp variant/* "${_TMPDIR}/" ;
pushd "${_TMPDIR}"
sed -i -e '/\/\/ variant-cli-output/r variant-cli-ouput-file' main.go
rm variant-cli-ouput-file main.go-e
popd
}

_build_image() {
  log "START:${FUNCNAME[0]}"
  if [[ "${DEBUG:=false}" == 'true' ]]; then
    readonly DOCKER_QUIET=false
  else
    readonly DOCKER_QUIET=true
  fi
  docker build --quiet=${DOCKER_QUIET} \
    -f dockerfiles/Dockerfile.golang \
    --tag ${REPO_OWNER}/golang:${GOLANG_VERSION} \
    --build-arg GOLANG_VERSION=${GOLANG_VERSION} \
    --build-arg GODEB_VERSION=${GODEB_VERSION} . ;
  docker build --quiet=${DOCKER_QUIET} \
    -f dockerfiles/Dockerfile.node \
    --tag ${REPO_OWNER}/node:${NODE_VERSION} \
    --build-arg NODE_VERSION=${NODE_VERSION} . ;
  log "END:${FUNCNAME[0]}"
}

_build_binary() {
  log "START:${FUNCNAME[0]}"
  cat > "${_TMPDIR}"/base64.tmp << EOF
  #!/bin/bash
  set -o errexit
  set -o nounset
  set -o pipefail
  [[ "${DEBUG:=false}" == 'true' ]] && set -o xtrace
  printf "${RED}---> downloading go dependencies     <---${NC}\n"
  printf "${RED}---> this can take a while depending <---${NC}\n"
  printf "${RED}---> on the speed of your internet   <---${NC}\n"
  if [[ "${DEBUG:=false}" == 'true' ]]; then
    GO111MODULE=on go mod download;
  else
    GO111MODULE=on go mod download;
  fi
  printf "${RED}---> building binary                 <---${NC}\n"
  go build -o ${CLI_NAME}-$GOOS-$GOARCH;
EOF
  MYCOMMAND=$(base64 -i "${_TMPDIR}"/base64.tmp)
  docker run -it --rm \
    -e GOOS="${GOOS}" \
    -e GOARCH="${GOARCH}" \
    -v gocache:/go/ \
    -v "${_TMPDIR}:${REPO_PATH}" \
		-w "${REPO_PATH}" \
		${REPO_OWNER}/golang:${GOLANG_VERSION} sh -c "echo "${MYCOMMAND}" | base64 --decode | bash";
  mv "${_TMPDIR}"/Gopkg.lock "$(pwd)"/variant;
  log "END:${FUNCNAME[0]}"
}

main() {
  st=$(date +%s)
  _variant
  _build_image
  _build_binary
  et=$(date +%s)
  log "${GREEN}Total Elasped: $((et - st)) seconds${NC}"
}

main "$@"
