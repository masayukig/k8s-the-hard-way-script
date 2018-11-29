#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd)

cat << EOF
#####################################
# 01. Prerequisites
# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/01-prerequisites.md#prerequisites
#####################################
EOF

echo "Install the Google Cloud SDK"
gcloud version

# Set a Default Compute Region and Zone
gcloud init

gcloud config set compute/region us-west1

gcloud config set compute/zone us-west1-c

echo; echo; echo
bash ${SCRIPT_DIR}/02-client-tools.sh

echo; echo; echo
bash ${SCRIPT_DIR}/03-compute-resources.sh

echo; echo; echo
bash ${SCRIPT_DIR}/04-certificate-authority.sh

echo; echo; echo
bash ${SCRIPT_DIR}/05-kubernetes-configuration-files.sh

echo; echo; echo
bash ${SCRIPT_DIR}/06-data-encryption-keys.sh

echo; echo; echo
bash ${SCRIPT_DIR}/07-bootstrapping-etcd.sh

echo; echo; echo
bash ${SCRIPT_DIR}/08-bootstrapping-kubernetes-controllers.sh

echo; echo; echo
bash ${SCRIPT_DIR}/09-bootstrapping-kubernetes-workers.sh

echo; echo; echo
bash ${SCRIPT_DIR}/10-configuring-kubectl.sh

echo; echo; echo
bash ${SCRIPT_DIR}/11-pod-network-routes.sh

echo; echo; echo
bash ${SCRIPT_DIR}/12-dns-addon.sh

echo; echo; echo
bash ${SCRIPT_DIR}/13-smoke-test.sh

echo; echo; echo
# bash ${SCRIPT_DIR}/14-cleanup.sh
