#!/bin/bash
set -euxo pipefail

changed='0'

find /usr/local/aws-cli/v2/ -mindepth 1 -maxdepth 1 -type d -not -name "$AWS_VERSION" | while read d; do
    rm -rf "$d"
    changed='1'
done

if [ "$changed" == '0' ]; then
    echo 'ANSIBLE CHANGED NO'
    exit 0
fi
