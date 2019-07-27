#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
[[ "${DEBUG:=false}" == 'true' ]] && set -o xtrace

if [[ $(aws sts get-caller-identity | jq -r '.Account') == $(yq r ~/.apl_config aws.account) ]]; then
  echo "we're good"
else
  echo "this is the wrong account"
fi