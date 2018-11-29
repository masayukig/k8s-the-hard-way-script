#!/usr/bin/env bash

cat << EOF
#####################################
# 02. Installing the Client Tools
# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/02-client-tools.md
#####################################
EOF

echo "Install CFSSL"
wget -q --show-progress --https-only --timestamping \
  https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 \
  https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64

chmod +x cfssl_linux-amd64 cfssljson_linux-amd64

sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl

sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson

echo "Verification"
cfssl version
echo "The output should be like this."
cat << EOF
The output should be like this.
Version: 1.2.0
Revision: dev
Runtime: go1.6
EOF

echo "Install kubectl"
wget https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl

chmod +x kubectl

sudo mv kubectl /usr/local/bin/

echo "Verification"
kubectl version --client
echo "The output should be like this."
cat << EOF
Client Version: version.Info{Major:"1", Minor:"12", GitVersion:"v1.12.0",
GitCommit:"0ed33881dc4355495f623c6f22e7dd0b7632b7c0", GitTreeState:"clean", BuildDate:"2018-09-27T17:05:32Z",
GoVersion:"go1.10.4", Compiler:"gc", Platform:"linux/amd64"}
EOF

cat << EOF