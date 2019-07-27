#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
[[ "${DEBUG:=false}" == 'true' ]] && set -o xtrace

readonly DOCKER_VOLUME="$(docker volume ls --filter=name="gocache" -q)"
readonly DOCKER_IMAGE="$(docker images --filter=reference="hireaprofessor/golang:*" -q)"

main() {
  rm -rf tmp.*
  
  echo ${DOCKER_VOLUME}
  echo ${DOCKER_IMAGE}

  if [[ -n ${DOCKER_VOLUME} ]]; then
    docker volume rm "${DOCKER_VOLUME}"
  fi;
  
  if [[ -n ${DOCKER_IMAGE} ]]; then
    docker rmi "${DOCKER_IMAGE}"
  fi
}

main "$@"
