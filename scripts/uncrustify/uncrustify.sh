#!/usr/bin/env bash

set -e
set -u
set -o pipefail

REPO_TOP_DIR=$(git rev-parse --show-toplevel)
CONFIG_FILE=${REPO_TOP_DIR}/scripts/uncrustify/uncrustify.cfg

cd ${REPO_TOP_DIR}

# memo:
# while syntax: while [env variable] read [option] [variable]; do ...
# IFS: bash environmental variable, internal field separator.

while IFS= read -rd '' GIT_STATUS
do
  IFS= read -rd '' FILEPATH

  [ "${GIT_STATUS}" == 'D' ] && continue

  FILEEXT="${FILEPATH##*.}"
  [ "${FILEEXT}" != 'h' ] && [ "${FILEEXT}" != 'm' ] && continue

  echo '***' "${GIT_STATUS}:${FILEPATH}"
  uncrustify -l oc -c ${CONFIG_FILE} --no-backup --mtime ${FILEPATH} 2>&1 || true
  rm ${FILEPATH}.uncrustify >/dev/null 2>&1 || true
  git add ${FILEPATH}
done < <(git diff --cached --name-status -z)
