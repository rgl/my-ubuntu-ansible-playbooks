#!/bin/bash
set -euo pipefail

command="$(basename "$0" .sh)"
tag="ansible-$(basename "$PWD")"

# build the ansible image.
DOCKER_BUILDKIT=1 docker build -f Dockerfile.ansible -t "$tag" .

# show information about the execution environment.
docker run --rm -i "$tag" bash <<'EOF'
exec 2>&1
set -euxo pipefail
cat /etc/os-release
ansible --version
python3 -m pip list
ansible-galaxy collection list
EOF

# execute command (e.g. ansible-playbook).
exec docker run --rm --net=host -v "$PWD:/playbooks:ro" "$tag" "$command" "$@"
