#!/usr/bin/env bash

set -e
set -u
set -o pipefail

TARGET_DIR="AnkokuAlert AnkokuAlertTests"

REPO_TOP_DIR=$(git rev-parse --show-toplevel)
CONFIG_FILE=${REPO_TOP_DIR}/scripts/uncrustify/uncrustify.cfg

for dir in ${TARGET_DIR}
do
  cd ${REPO_TOP_DIR}/${dir}
  echo '***' $(pwd)
  for file in $(find . -name '*.h' -o -name '*.m')
  do
    uncrustify -l OC -c ${CONFIG_FILE} --no-backup ${file}
  done
done
