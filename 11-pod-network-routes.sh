#!/usr/bin/env bash


cat << EOF
#####################################
# 11. Provisioning Pod Network Routes
# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/11-pod-network-routes.md
#####################################
EOF

echo "============== Pods scheduled to a node receive an IP address from the node's Pod CIDR range."
echo "============== At this point pods can not communicate with other pods running on different nodes"
echo "============== due to missing network routes."

echo "============== In this lab you will create a route for each worker node that maps the node's Pod CIDR range to the node's internal IP address."

echo "============== The Routing Table"
echo "============== In this section you will gather the information required to create routes in the kubernetes-the-hard-way VPC network."
echo "============== Print the internal IP address and Pod CIDR range for each worker instance:"
for instance in worker-0 worker-1 worker-2; do
  gcloud compute instances describe ${instance} \
    --format 'value[separator=" "](networkInterfaces[0].networkIP,metadata.items[0].value)'
done

echo "============== The output should be like this"
cat << EOF
10.240.0.20 10.200.0.0/24
10.240.0.21 10.200.1.0/24
10.240.0.22 10.200.2.0/24
EOF

echo "============== Routes"
echo "============== Create network routes for each worker instance:"
for i in 0 1 2; do
  gcloud compute routes create kubernetes-route-10-200-${i}-0-24 \
    --network kubernetes-the-hard-way \
    --next-hop-address 10.240.0.2${i} \
    --destination-range 10.200.${i}.0/24
done

echo "============== List the routes in the kubernetes-the-hard-way VPC network:"

gcloud compute routes list --filter "network: kubernetes-the-hard-way"

echo "============== The output should be like this"
cat << EOF
NAME                            NETWORK                  DEST_RANGE     NEXT_HOP                  PRIORITY
default-route-081879136902de56  kubernetes-the-hard-way  10.240.0.0/24  kubernetes-the-hard-way   1000
default-route-55199a5aa126d7aa  kubernetes-the-hard-way  0.0.0.0/0      default-internet-gateway  1000
kubernetes-route-10-200-0-0-24  kubernetes-the-hard-way  10.200.0.0/24  10.240.0.20               1000
kubernetes-route-10-200-1-0-24  kubernetes-the-hard-way  10.200.1.0/24  10.240.0.21               1000
kubernetes-route-10-200-2-0-24  kubernetes-the-hard-way  10.200.2.0/24  10.240.0.22               1000
EOF
