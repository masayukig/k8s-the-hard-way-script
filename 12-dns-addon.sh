#!/usr/bin/env bash


cat << EOF
#####################################
# 12. Deploying the DNS Cluster Add-on
# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/12-dns-addon.md
#####################################
EOF

echo "============== In this lab you will deploy the DNS add-on which provides DNS based service discovery, backed by CoreDNS, to applications running inside the Kubernetes cluster."
echo "============== The DNS Cluster Add-on"
echo "============== Deploy the coredns cluster add-on:"
kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns.yaml

echo "============== The output should be like this"
cat << EOF
serviceaccount/coredns created
clusterrole.rbac.authorization.k8s.io/system:coredns created
clusterrolebinding.rbac.authorization.k8s.io/system:coredns created
configmap/coredns created
deployment.extensions/coredns created
service/kube-dns created
EOF

echo "============== List the pods created by the kube-dns deployment:"
kubectl get pods -l k8s-app=kube-dns -n kube-system

echo "============== The output should be like this"
cat << EOF
NAME                       READY   STATUS    RESTARTS   AGE
coredns-699f8ddd77-94qv9   1/1     Running   0          20s
coredns-699f8ddd77-gtcgb   1/1     Running   0          20s
EOF

echo "============== Verification"
echo "============== Create a busybox deployment:"
kubectl run busybox --image=busybox:1.28 --command -- sleep 3600

echo "============== Wait for the busybox deployment"
sleep 10
echo "============== List the pod created by the busybox deployment:"
kubectl get pods -l run=busybox

echo "============== The output should be like this"
cat << EOF
NAME                      READY   STATUS    RESTARTS   AGE
busybox-bd8fb7cbd-vflm9   1/1     Running   0          10s
EOF

echo "============== Retrieve the full name of the busybox pod:"
POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")

echo "============== Execute a DNS lookup for the kubernetes service inside the busybox pod:"
kubectl exec -ti $POD_NAME -- nslookup kubernetes

echo "============== The output should be like this"
cat << EOF
Server:    10.32.0.10
Address 1: 10.32.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.32.0.1 kubernetes.default.svc.cluster.local
EOF
