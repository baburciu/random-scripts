#!/bin/bash

TOKEN=$(cat vault_client_token.txt)     # get it from Vault UI 
VAULT="192.168.y.y"
SUBCA="extca"

cat > payload.json << EOF
{
  "common_name":"netbox.dnszone",
  "ip_sans":"192.168.x.x,127.0.0.1",
  "format":"pem",
  "ttl":"20h"
}
EOF

curl -k -H "X-Vault-Token:${TOKEN}"  --request POST --data @payload.json https://${VAULT}:8200/v1/${SUBCA}/issue/kaas-cert-issuer  > reply.json

cat reply.json | jq ".data.certificate" > ./vault_netbox_cert_1.crt
sed -i 's/\\n/\n/g' ./vault_netbox_cert_1.crt
sed -i 's/"//g' ./vault_netbox_cert_1.crt

cat reply.json | jq ".data.private_key" > ./vault_netbox_key_1.key
sed -i 's/\\n/\n/g' ./vault_netbox_key_1.key
sed -i 's/"//g' ./vault_netbox_key_1.key
