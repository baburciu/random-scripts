#!/usr/bin/python3

# run as: eval $(python3 get_ceph_secrets_vault_jwt.py --ssh-key bogdan.burciu_privKey.key --username bogdan.burciu)

    # cat requirements.txt
    #     boto3==1.17.53
    #     PyJWT==2.1.0
    #     sshtunnel==0.4.0
    # pip3 install -r requirements.txt

import jwt
import time
import argparse
import requests
import sshtunnel
import json
import os

# vars for JWT creation
SUB = '1234567890'
TTL = 3600  # seconds

# vars for Vault
VAULT_IP="192.168.x.x"
VAULT_PORT=8200
VAULT_ROLE="gitlab_ci_runner"
REMOTE_SERVER_IP = "bastion.random.net"


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument('--ssh-key',
                        dest='ssh_key',
                        action='store',
                        required=True,
                        help='the path for ssh private key, for which JWT is issued')

    parser.add_argument('--username',
                        dest='name',
                        action='store',
                        required=True,
                        help='the name of the user owning the private key, for which JWT is issued')
    args = parser.parse_args()

    key_file = args.ssh_key
    ssh_user = args.name

    # create JWT from ssh private key
    private = open(key_file, 'r').read()
    encoded_jwt = jwt.encode({'name': ssh_user, 'sub': SUB, "iat": (time.time()), "exp": int(time.time()) + TTL},
                             private, 'RS256')

    # open SSH tunnel from GitLab Runner to the Vault endpoint
    server = sshtunnel.SSHTunnelForwarder(
        (REMOTE_SERVER_IP, 20022),
        ssh_username=ssh_user,
        ssh_pkey=args.ssh_key,
        remote_bind_address=(VAULT_IP, VAULT_PORT),
        local_bind_address=('127.0.0.1', VAULT_PORT),
        mute_exceptions=True
    )
    server.start()

    # feth the Vault Client Token upon authentication with JWT
    result = requests.post(url=create_url('auth/jwt/login'), data={'jwt': encoded_jwt, 'role': VAULT_ROLE},
                           verify=False)
    vault_client_token = result.json()['auth']['client_token']

    # read the Ceph S3 secret credentials from Vault, using Client Token
    result = requests.get(url=create_url('secret/data/neo/ceph?version=1'),
                          headers={'X-Vault-Token': vault_client_token, 'Content-type': 'application/json'},
                          verify=False)
    s3_access_key_id = result.json()['data']['data']['s3_access_key_id']
    s3_secret_access_key = result.json()['data']['data']['s3_secret_access_key']

    # we output export commands and have the parent shell evaluate this to set env vars
    print("export S3_ACCESS_KEY_ID=%s" % s3_access_key_id)
    print("export S3_SECRET_ACCESS_KEY=%s" % s3_secret_access_key)

    # stop SSH tunnel
    server.stop()


# create URI; takes two parameters: the API path and the Vault socket forwarded to localhost same port
def create_url(path):
    """ Helper function to create a Vault API endpoint URL
    """
    return "https://127.0.0.1:%s/v1/%s" % (VAULT_PORT, path)


if __name__ == '__main__':
    main()
