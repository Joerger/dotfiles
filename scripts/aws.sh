#!/bin/sh

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
rm awscliv2.zip
sudo ./aws/install --bin-dir $TOOL_BIN --install-dir $TOOLS/aws --update
rm -r ./aws
