#!/usr/bin/python3

# run as "python3 create_jwt_from_key.py --ssh-key bogdan.burciu_privKey.key --username bogdan.burciu"

import jwt
import time
import argparse

SUB = '1234567890'
TTL = 3600  # seconds


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

    KEY_FILE = args.ssh_key
    NAME = args.name

    private = open(KEY_FILE, 'r').read()

    encoded_jwt = jwt.encode({'name': NAME, 'sub': SUB, "iat": (time.time()), "exp": int(time.time())+TTL}, private, 'RS256')

    print(encoded_jwt)


if __name__ == '__main__':
    main()

