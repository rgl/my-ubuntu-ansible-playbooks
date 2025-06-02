#!/bin/bash
set -euo pipefail

# shellcheck disable=SC2088
if [[ "$PASSWORD_PATH" == '~/'* ]]; then
  PASSWORD_PATH="${PASSWORD_PATH/#~/$HOME}"
fi

if [ ! -f "$PASSWORD_PATH" ]; then
  echo 'ANSIBLE CHANGED YES'
  install -m 600 /dev/null "$PASSWORD_PATH"
  (tr -dc 'A-Za-z0-9!?%=' < /dev/urandom | head -c 15 > "$PASSWORD_PATH") || true
fi

cat "$PASSWORD_PATH"
