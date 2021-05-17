#!/bin/bash

# Attention!!! Needs to be run like " . get_ceph_secret_vault.sh" OR "source get_ceph_secret_vault.sh" for env var to remain set

VAULT=192.168.x.x
ROLE=gitlab_ci_runner

# create JWT from ssh private key
JWT=$(python3 scripts/create_jwt_from_key.py --ssh-key ${PWD}/id_rsa --username bogdan.burciu)

# open SSH tunnel to bastion (without remote command), in order to reach Vault
ssh -4 -o StrictHostKeyChecking=no -i ${PWD}/id_rsa -l bogdan.burciu -p 20022 bastion.random.net -D 8888 -f -N -M -S /tmp/burciu_bastion_session

# uncomment for t-shooting
# curl -k -XPOST  --data "{\"jwt\":\"${JWT}\", \"role\": \"${ROLE}\"}" https://${VAULT}:8200/v1/auth/jwt/login --socks5 127.0.0.1:8888 

CLIENT_TOKEN=$(curl -k -XPOST  --data "{\"jwt\":\"${JWT}\", \"role\": \"${ROLE}\"}" --socks5 127.0.0.1:8888  https://${VAULT}:8200/v1/auth/jwt/login | jq -r '.auth.client_token')

# export the secret values from Vault as env vars
export S3_ACCESS_KEY_ID=$(curl -s -k -X GET -H "X-Vault-Token: $CLIENT_TOKEN" -H "accept: application/json" --socks5 127.0.0.1:8888  https://${VAULT}:8200/v1/secret/data/neo/ceph?version=1  | jq ".data.data.s3_access_key_id") 

export S3_SECRET_ACCESS_KEY=$(curl -s -k -X GET -H "X-Vault-Token: $CLIENT_TOKEN" -H "accept: application/json" --socks5 127.0.0.1:8888 https://${VAULT}:8200/v1/secret/data/neo/ceph?version=1  | jq ".data.data.s3_secret_access_key")

# close SSH tunnel with bastion
ssh -S /tmp/burciu_bastion_session -O exit bastion.random.net
