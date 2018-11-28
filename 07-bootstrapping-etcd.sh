#!/usr/bin/env bash


cat << EOF
#####################################
# 07. Bootstrapping the etcd Cluster
# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/07-bootstrapping-etcd.md
#####################################
EOF

echo "============== Prerequisites"

echo '
    echo "============== Download and Install the etcd Binaries"
    echo "============== Download the official etcd release binaries from the coreos/etcd GitHub project:"

    wget -q --show-progress --https-only --timestamping \
      "https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz"

    echo "============== Extract and install the etcd server and the etcdctl command line utility:"
    {
      tar -xvf etcd-v3.3.9-linux-amd64.tar.gz
      sudo mv etcd-v3.3.9-linux-amd64/etcd* /usr/local/bin/
    }

    echo "============== Configure the etcd Server"
    {
      sudo mkdir -p /etc/etcd /var/lib/etcd
      sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
    }

    INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
      http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

    ETCD_NAME=$(hostname -s)

    cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller-0=https://10.240.0.10:2380,controller-1=https://10.240.0.11:2380,controller-2=https://10.240.0.12:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    echo "============== Start the etcd Server"
    {
      sudo systemctl daemon-reload
      sudo systemctl enable etcd
      sudo systemctl start etcd
    }

    echo "============== Verification"
    sudo ETCDCTL_API=3 etcdctl member list \
      --endpoints=https://127.0.0.1:2379 \
      --cacert=/etc/etcd/ca.pem \
      --cert=/etc/etcd/kubernetes.pem \
      --key=/etc/etcd/kubernetes-key.pem

    echo "============== The output should be like this"
    cat << EOF
3a57933972cb5131, started, controller-2, https://10.240.0.12:2380, https://10.240.0.12:2379
f98dc20bce6225a0, started, controller-0, https://10.240.0.10:2380, https://10.240.0.10:2379
ffed16798470cab5, started, controller-1, https://10.240.0.11:2380, https://10.240.0.11:2379
EOF

' > bootstrapping_an_etcd_cluster.sh

for instance in controller-0 controller-1 controller-2; do
  gcloud compute ssh ${instance} -- 'bash -s' < bootstrapping_an_etcd_cluster.sh
done
