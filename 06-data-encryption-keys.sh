#!/usr/bin/env bash


cat << EOF
#####################################
# 06. Generating the Data Encryption Config and Key
# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/06-data-encryption-keys.md
#####################################
EOF

echo "============== The Encryption Key"
echo "============== Generate an encryption key:"
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

echo "============== The Encryption Config File"
echo "============== Create the encryption-config.yaml encryption config file:"
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

echo "============== Copy the encryption-config.yaml encryption config file to each controller instance:"
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp encryption-config.yaml ${instance}:~/
done
