#!/usr/bin/env bash


cat << EOF
#####################################
# 13. Smoke Test
# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/13-smoke-test.md
#####################################
EOF

echo "============== In this lab you will complete a series of tasks to ensure your Kubernetes cluster is functioning correctly."
echo "============== Data Encryption"
echo "============== In this section you will verify the ability to encrypt secret data at rest."
echo "============== Create a generic secret:"
kubectl create secret generic kubernetes-the-hard-way \
  --from-literal="mykey=mydata"

echo "============== Print a hexdump of the kubernetes-the-hard-way secret stored in etcd:"
gcloud compute ssh controller-0 \
  --command "sudo ETCDCTL_API=3 etcdctl get \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem\
  /registry/secrets/default/kubernetes-the-hard-way | hexdump -C"

echo "============== The output should be like this"
cat << EOF
00000000  2f 72 65 67 69 73 74 72  79 2f 73 65 63 72 65 74  |/registry/secret|
00000010  73 2f 64 65 66 61 75 6c  74 2f 6b 75 62 65 72 6e  |s/default/kubern|
00000020  65 74 65 73 2d 74 68 65  2d 68 61 72 64 2d 77 61  |etes-the-hard-wa|
00000030  79 0a 6b 38 73 3a 65 6e  63 3a 61 65 73 63 62 63  |y.k8s:enc:aescbc|
00000040  3a 76 31 3a 6b 65 79 31  3a dd 3f 36 6c ce 65 9d  |:v1:key1:.?6l.e.|
00000050  b3 b1 46 1a ba ae a2 1f  e4 fa 13 0c 4b 6e 2c 3c  |..F.........Kn,<|
00000060  15 fa 88 56 84 b7 aa c0  7a ca 66 f3 de db 2b a3  |...V....z.f...+.|
00000070  88 dc b1 b1 d8 2f 16 3e  6b 4a cb ac 88 5d 23 2d  |...../.>kJ...]#-|
00000080  99 62 be 72 9f a5 01 38  15 c4 43 ac 38 5f ef 88  |.b.r...8..C.8_..|
00000090  3b 88 c1 e6 b6 06 4f ae  a8 6b c8 40 70 ac 0a d3  |;.....O..k.@p...|
000000a0  3e dc 2b b6 0f 01 b6 8b  e2 21 29 4d 32 d6 67 a6  |>.+......!)M2.g.|
000000b0  4e 6d bb 61 0d 85 22 ea  f4 d6 2d 0a af 3c 71 85  |Nm.a.."...-..<q.|
000000c0  96 27 c9 ec 90 e3 56 8c  94 a7 1c 9a 0e 00 28 11  |.'....V.......(.|
000000d0  18 28 f4 33 42 d9 57 d9  e3 e9 1c 38 e3 bc 1e c3  |.(.3B.W....8....|
000000e0  d2 47 f3 20 60 be b8 57  a7 0a                    |.G. ...W..|
000000ea
EOF
echo "============== The etcd key should be prefixed with k8s:enc:aescbc:v1:key1, which indicates the aescbc provider was used to encrypt the data with the key1 encryption key."

echo "============== Deployments"
echo "============== In this section you will verify the ability to create and manage Deployments."
echo "============== Create a deployment for the nginx web server:"
kubectl run nginx --image=nginx

echo "============== List the pod created by the nginx deployment:"
kubectl get pods -l run=nginx
echo "============== The output should be like this"
cat << EOF
NAME                    READY   STATUS    RESTARTS   AGE
nginx-dbddb74b8-6lxg2   1/1     Running   0          10s
EOF

echo "============== Port Forwarding"
echo "============== In this section you will verify the ability to access applications remotely using port forwarding."
echo "============== Retrieve the full name of the nginx pod:"
POD_NAME=$(kubectl get pods -l run=nginx -o jsonpath="{.items[0].metadata.name}")

echo "============== Forward port 8080 on your local machine to port 80 of the nginx pod:"
kubectl port-forward $POD_NAME 8080:80
echo "==============     output should be like this"
cat << EOF
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
EOF

echo "============== In a new terminal make an HTTP request using the forwarding address:"
curl --head http://127.0.0.1:8080
echo "==============     output should be like this"
cat << EOF
HTTP/1.1 200 OK
Server: nginx/1.15.4
Date: Sun, 30 Sep 2018 19:23:10 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 25 Sep 2018 15:04:03 GMT
Connection: keep-alive
ETag: "5baa4e63-264"
Accept-Ranges: bytes
EOF

echo "============== Switch back to the previous terminal and stop the port forwarding to the nginx pod:"
cat << EOF
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
Handling connection for 8080
^C
EOF

echo "============== Logs"
echo "============== In this section you will verify the ability to retrieve container logs."
echo "============== Print the nginx pod logs:"
kubectl logs $POD_NAME
echo "==============     output should be like this"
cat << EOF
127.0.0.1 - - [30/Sep/2018:19:23:10 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.58.0" "-"
EOF

echo "============== Exec"
echo "============== In this section you will verify the ability to execute commands in a container."
echo "============== Print the nginx version by executing the nginx -v command in the nginx container:"
kubectl exec -ti $POD_NAME -- nginx -v

echo "==============     output should be like this"
cat << EOF
nginx version: nginx/1.15.4
EOF

echo "============== Services"
echo "============== In this section you will verify the ability to expose applications using a Service."
echo "============== Expose the nginx deployment using a NodePort service:"
kubectl expose deployment nginx --port 80 --type NodePort

echo "============== Retrieve the node port assigned to the nginx service:"
NODE_PORT=$(kubectl get svc nginx \
  --output=jsonpath='{range .spec.ports[0]}{.nodePort}')

echo "============== Create a firewall rule that allows remote access to the nginx node port:"
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-nginx-service \
  --allow=tcp:${NODE_PORT} \
  --network kubernetes-the-hard-way

echo "============== Retrieve the external IP address of a worker instance:"
EXTERNAL_IP=$(gcloud compute instances describe worker-0 \
  --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')

echo "============== Make an HTTP request using the external IP address and the nginx node port:"
curl -I http://${EXTERNAL_IP}:${NODE_PORT}

echo "==============     output should be like this"
cat << EOF
HTTP/1.1 200 OK
Server: nginx/1.15.4
Date: Sun, 30 Sep 2018 19:25:40 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 25 Sep 2018 15:04:03 GMT
Connection: keep-alive
ETag: "5baa4e63-264"
Accept-Ranges: bytes
EOF

echo "============== Untrusted Workloads"
echo "============== This section will verify the ability to run untrusted workloads using gVisor."
echo "============== Create the untrusted pod:"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: untrusted
  annotations:
    io.kubernetes.cri.untrusted-workload: "true"
spec:
  containers:
    - name: webserver
      image: gcr.io/hightowerlabs/helloworld:2.0.0
EOF


echo "============== Verification"
echo "============== In this section you will verify the untrusted pod is running under gVisor (runsc) by inspecting the assigned worker node."

echo "============== Verify the untrusted pod is running:"
kubectl get pods -o wide
echo "============== output should be like this"
cat << EOF
NAME                       READY     STATUS    RESTARTS   AGE       IP           NODE
busybox-68654f944b-djjjb   1/1       Running   0          5m        10.200.0.2   worker-0
nginx-65899c769f-xkfcn     1/1       Running   0          4m        10.200.1.2   worker-1
untrusted                  1/1       Running   0          10s       10.200.0.3   worker-0
EOF

echo "============== Get the node name where the untrusted pod is running:"
INSTANCE_NAME=$(kubectl get pod untrusted --output=jsonpath='{.spec.nodeName}')


echo '
echo "============== List the containers running under gVisor:"
sudo runsc --root  /run/containerd/runsc/k8s.io list
echo "============== output should be like this"
cat << EOF
I0930 19:27:13.255142   20832 x:0] ***************************
I0930 19:27:13.255326   20832 x:0] Args: [runsc --root /run/containerd/runsc/k8s.io list]
I0930 19:27:13.255386   20832 x:0] Git Revision: 50c283b9f56bb7200938d9e207355f05f79f0d17
I0930 19:27:13.255429   20832 x:0] PID: 20832
I0930 19:27:13.255472   20832 x:0] UID: 0, GID: 0
I0930 19:27:13.255591   20832 x:0] Configuration:
I0930 19:27:13.255654   20832 x:0]              RootDir: /run/containerd/runsc/k8s.io
I0930 19:27:13.255781   20832 x:0]              Platform: ptrace
I0930 19:27:13.255893   20832 x:0]              FileAccess: exclusive, overlay: false
I0930 19:27:13.256004   20832 x:0]              Network: sandbox, logging: false
I0930 19:27:13.256128   20832 x:0]              Strace: false, max size: 1024, syscalls: []
I0930 19:27:13.256238   20832 x:0] ***************************
ID                                                                 PID         STATUS      BUNDLE                                                                                                                   CREATED                OWNER
79e74d0cec52a1ff4bc2c9b0bb9662f73ea918959c08bca5bcf07ddb6cb0e1fd   20449       running     /run/containerd/io.containerd.runtime.v1.linux/k8s.io/79e74d0cec52a1ff4bc2c9b0bb9662f73ea918959c08bca5bcf07ddb6cb0e1fd   0001-01-01T00:00:00Z
af7470029008a4520b5db9fb5b358c65d64c9f748fae050afb6eaf014a59fea5   20510       running     /run/containerd/io.containerd.runtime.v1.linux/k8s.io/af7470029008a4520b5db9fb5b358c65d64c9f748fae050afb6eaf014a59fea5   0001-01-01T00:00:00Z
I0930 19:27:13.259733   20832 x:0] Exiting with status: 0
EOF

echo "============== Get the ID of the untrusted pod:"
POD_ID=$(sudo crictl -r unix:///var/run/containerd/containerd.sock \
  pods --name untrusted -q)

echo "============== Get the ID of the webserver container running in the untrusted pod:"
CONTAINER_ID=$(sudo crictl -r unix:///var/run/containerd/containerd.sock \
  ps -p ${POD_ID} -q)

echo "============== Use the gVisor runsc command to display the processes running inside the webserver container:"
sudo runsc --root /run/containerd/runsc/k8s.io ps ${CONTAINER_ID}

echo "============== output should be like this"
cat << EOF
I0930 19:31:31.419765   21217 x:0] ***************************
I0930 19:31:31.419907   21217 x:0] Args: [runsc --root /run/containerd/runsc/k8s.io ps af7470029008a4520b5db9fb5b358c65d64c9f748fae050afb6eaf014a59fea5]
I0930 19:31:31.419959   21217 x:0] Git Revision: 50c283b9f56bb7200938d9e207355f05f79f0d17
I0930 19:31:31.420000   21217 x:0] PID: 21217
I0930 19:31:31.420041   21217 x:0] UID: 0, GID: 0
I0930 19:31:31.420081   21217 x:0] Configuration:
I0930 19:31:31.420115   21217 x:0]              RootDir: /run/containerd/runsc/k8s.io
I0930 19:31:31.420188   21217 x:0]              Platform: ptrace
I0930 19:31:31.420266   21217 x:0]              FileAccess: exclusive, overlay: false
I0930 19:31:31.420424   21217 x:0]              Network: sandbox, logging: false
I0930 19:31:31.420515   21217 x:0]              Strace: false, max size: 1024, syscalls: []
I0930 19:31:31.420676   21217 x:0] ***************************
UID       PID       PPID      C         STIME     TIME      CMD
0         1         0         0         19:26     10ms      app
I0930 19:31:31.422022   21217 x:0] Exiting with status: 0
EOF
' > smoke-verification.sh

echo "============== SSH into the worker node and verify:"
gcloud compute ssh ${INSTANCE_NAME} -- 'bash -s' < smoke-verification.sh



