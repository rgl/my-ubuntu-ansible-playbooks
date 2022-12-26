set -euo pipefail

# bail when already installed.
if [ -x /usr/local/bin/aws ]; then
    # e.g. aws-cli/2.9.10 Python/3.9.11 Linux/5.15.0-56-generic exe/x86_64.ubuntu.22 prompt/off
    actual_version="$(/usr/local/bin/aws --version | perl -ne '/^aws-cli\/(.+?) / && print $1')"
    if [ "$actual_version" == "$AWS_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
# see https://docs.aws.amazon.com/cli/latest/userguide/getting-started-version.html
aws_url="https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_VERSION}.zip"
t="$(mktemp -q -d --suffix=.aws)"
wget -qO "$t/awscli.zip" "$aws_url"
unzip "$t/awscli.zip" -d "$t"
"$t/aws/install" \
    --bin-dir /usr/local/bin \
    --install-dir /usr/local/aws-cli \
    --update
rm -rf "$t"
