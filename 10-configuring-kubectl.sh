#!/usr/bin/env bash


cat << EOF
#####################################
# 10. Configuring kubectl for Remote Access
# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/10-configuring-kubectl.md
#####################################
EOF

echo "============== In this lab you will generate a kubeconfig file for the kubectl command line utility based on the admin user credentials."
echo "============== The Admin Kubernetes Configuration File"
echo "============== Generate a kubeconfig file suitable for authenticating as the admin user:"
{
  KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
    --region $(gcloud config get-value compute/region) \
    --format 'value(address)')

  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem

  kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

  kubectl config use-context kubernetes-the-hard-way
}

echo "============== Verification"
echo "============== Check the health of the remote Kubernetes cluster:"
kubectl get componentstatuses

echo "============== The output should be like this"
cat << EOF
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-1               Healthy   {"health":"true"}
etcd-2               Healthy   {"health":"true"}
etcd-0               Healthy   {"health":"true"}
EOF

echo "============== List the nodes in the remote Kubernetes cluster:"
kubectl get nodes
echo "============== The output should be like this"
cat << EOF
NAME       STATUS   ROLES    AGE    VERSION
worker-0   Ready    <none>   117s   v1.12.0
worker-1   Ready    <none>   118s   v1.12.0
worker-2   Ready    <none>   118s   v1.12.0
EOF
