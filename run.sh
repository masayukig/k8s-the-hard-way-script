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

echo; echo; echo

cat << EOF
#####################################
# 03. Provisioning Compute Resources
# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/03-compute-resources.md
#####################################
EOF

echo "Networking"
echo "Create the 'kubernetes-the-hard-way' custom VPC network:"
gcloud compute networks create kubernetes-the-hard-way --subnet-mode custom

echo "Create the 'kubernetes' subnet in the 'kubernetes-the-hard-way' VPC network:"
gcloud compute networks subnets create kubernetes \
  --network kubernetes-the-hard-way \
  --range 10.240.0.0/24

echo "Firewall Rules"
echo "Create a firewall rule that allows internal communication across all protocols:"
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-internal \
  --allow tcp,udp,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 10.240.0.0/24,10.200.0.0/16

echo "Create a firewall rule that allows external SSH, ICMP, and HTTPS:"
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-external \
  --allow tcp:22,tcp:6443,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 0.0.0.0/0
echo "An external load balancer will be used to expose the Kubernetes API Servers to remote clients."

echo "List the firewall rules in the kubernetes-the-hard-way VPC network:"
gcloud compute firewall-rules list --filter="network:kubernetes-the-hard-way"

echo "The output should be like this."
cat << EOF
NAME                                    NETWORK                  DIRECTION  PRIORITY  ALLOW                 DENY
kubernetes-the-hard-way-allow-external  kubernetes-the-hard-way  INGRESS    1000      tcp:22,tcp:6443,icmp
kubernetes-the-hard-way-allow-internal  kubernetes-the-hard-way  INGRESS    1000      tcp,udp,icmp
EOF

echo "Kubernetes Public IP Address"
echo "Allocate a static IP address that will be attached to the external load balancer fronting the Kubernetes API Servers:"
gcloud compute addresses create kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region)

echo "Verify the kubernetes-the-hard-way static IP address was created in your default compute region:"
gcloud compute addresses list --filter="name=('kubernetes-the-hard-way')"

echo "The output should be like this."
cat << EOF
NAME                     REGION    ADDRESS        STATUS
kubernetes-the-hard-way  us-west1  XX.XXX.XXX.XX  RESERVED
EOF

echo "Compute Instances"
echo "Kubernetes Controllers"
echo "Create three compute instances which will host the Kubernetes control plane:"
for i in 0 1 2; do
  gcloud compute instances create controller-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --private-network-ip 10.240.0.1${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,controller
done

echo "Kubernetes Workers"
echo "Create three compute instances which will host the Kubernetes worker nodes:"
for i in 0 1 2; do
  gcloud compute instances create worker-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --metadata pod-cidr=10.200.${i}.0/24 \
    --private-network-ip 10.240.0.2${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,worker
done

echo "Verification"
echo "List the compute instances in your default compute zone:"
gcloud compute instances list

echo "The output should be like this."
cat << EOF
NAME          ZONE        MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP     STATUS
controller-0  us-west1-c  n1-standard-1               10.240.0.10  XX.XXX.XXX.XXX  RUNNING
controller-1  us-west1-c  n1-standard-1               10.240.0.11  XX.XXX.X.XX     RUNNING
controller-2  us-west1-c  n1-standard-1               10.240.0.12  XX.XXX.XXX.XX   RUNNING
worker-0      us-west1-c  n1-standard-1               10.240.0.20  XXX.XXX.XXX.XX  RUNNING
worker-1      us-west1-c  n1-standard-1               10.240.0.21  XX.XXX.XX.XXX   RUNNING
worker-2      us-west1-c  n1-standard-1               10.240.0.22  XXX.XXX.XX.XX   RUNNING
EOF

echo "Configuring SSH Access"
echo "Test SSH access to the controller-0 compute instances:"
echo "If this is your first time connecting to a compute instance SSH keys will be generated for you. Enter a passphrase at the prompt to continue:"
gcloud compute ssh controller-0 -- exit

echo "The output should be like this."
cat << EOF
logout
Connection to XX.XXX.XXX.XXX closed
EOF

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
