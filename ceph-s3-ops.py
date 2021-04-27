#! /usr/bin/env python3

    # How to run: 
    #     boburciu@WX-5CG020BDT2:$ python3 Py_scripts/ceph_s3_ops.py  --ssh-key /.ssh/id_rsa -h
    #      usage: ceph_s3_ops.py [-h] --ssh-key SSH_KEY
    #                            {create_s3_bucket,upload_s3_bucket,query_s3_bucket,download_s3_bucket}
    #                            ...
    #     positional arguments:
    #        {create_s3_bucket,upload_s3_bucket,query_s3_bucket,download_s3_bucket}
    #                              Desired action to perform
    #          create_s3_bucket    Creates an S3 bucket
    #          upload_s3_bucket    Push file from S3 bucket
    #          query_s3_bucket     Queries an S3 bucket
    #          download_s3_bucket  Get file from S3 bucket
    #     optional arguments:
    #        h, -help            show this help message and exit
    #        --ssh-key SSH_KEY     the path for ssh key; common for all script options
    #      boburciu@WX-5CG020BDT2:~$
    #      boburciu@WX-5CG020BDT2:$ python3 Py_scripts/ceph_s3_ops.py  --ssh-key /.ssh/id_rsa upload_s3_bucket -h
    #      usage: ceph_s3_ops.py upload_s3_bucket [-h] --bucket-name BUCKET_NAME
    #                                             -key-name KEY_NAME -file-name
    #                                             FILE_NAME
    #     optional arguments:
    #        h, -help            show this help message and exit
    #        --bucket-name BUCKET_NAME
    #                              the name of the bucket to push to
    #        --key-name KEY_NAME   the objects key name
    #        --file-name FILE_NAME
    #                              the path of the file to be uploaded
    #
    # Credits and more examples:
    #     - https://github.com/ronaldddilley/ceph-s3-examples/

import sshtunnel
import argparse
import boto3

S3_CEPH_CREDENTIALS = {
    "s3_endpoint_url": "http://127.0.0.1:33380",
    "s3_access_key_id": "@#$%^&*(",
    "s3_secret_access_key": "@#$%^&*(12345"
}

REMOTE_SERVER_IP = "@#$%^&*(.net"   # SSH tunnel termination
SSH_USER = "bogdan.burciu"          
PRIVATE_SERVER_IP = "192.168.1.1"   # Ceph S3 endpoint behind SSH tunnel

def main():
    # Main parser
    parser = argparse.ArgumentParser()

    # Usual arguments which are applicable for the whole script / top-level args; the SSH key
    parser.add_argument('--ssh-key',
                        dest='ssh_key',
                        action='store',
                        required=True,
                        help='the path for ssh key; common for all script options')

    # Subparsers
    subparsers = parser.add_subparsers(help='Desired action to perform', dest='action')

    # Create parent subparser. Note `add_help=False` and creation via `argparse.`
    parent_parser = argparse.ArgumentParser(add_help=False)

    # Subparsers based on parent
    # the operation of creating an S3 Ceph bucket
    parser_create = subparsers.add_parser("create_s3_bucket", parents=[parent_parser],
                                          help='Creates an S3 bucket')
    # Add some arguments exclusively for parser_create
    parser_create.add_argument('--bucket-name',
                               dest='bucket_name',
                               action='store',
                               required=True,
                               help='the name of the bucket to create')

    # the operation of pushing/updating the S3 Ceph bucket:
    parser_upload = subparsers.add_parser("upload_s3_bucket", parents=[parent_parser],
                                          help='Push file to S3 bucket')
    # Add some arguments exclusively for parser_upload
    parser_upload.add_argument('--bucket-name',
                               dest='bucket_name',
                               action='store',
                               required=True,
                               help='the name of the bucket to push to')
    parser_upload.add_argument('--key-name',
                               dest='key_name',
                               action='store',
                               required=True,
                               help='the objects key name')
    parser_upload.add_argument('--file-name',
                               dest='file_name',
                               action='store',
                               required=True,
                               help='the path of the file to be uploaded')

    # the operation of querying an S3 Ceph bucket
    parser_query = subparsers.add_parser("query_s3_bucket", parents=[parent_parser],
                                         help='Queries an S3 bucket')
    # Add some arguments exclusively for parser_create
    parser_query.add_argument('--bucket-name',
                              dest='bucket_name',
                              action='store',
                              required=True,
                              help='the name of the bucket to query contents for')

    # the operation of downloading from the S3 Ceph bucket:
    parser_download = subparsers.add_parser("download_s3_bucket", parents=[parent_parser],
                                            help='Get file from S3 bucket')
    # Add some arguments exclusively for parser_download
    parser_download.add_argument('--bucket-name',
                                 dest='bucket_name',
                                 action='store',
                                 required=True,
                                 help='the name of the bucket to download from')
    parser_download.add_argument('--key-name',
                                 dest='key_name',
                                 action='store',
                                 required=True,
                                 help='the objects key name')
    parser_download.add_argument('--file-name',
                                 dest='file_name',
                                 action='store',
                                 required=True,
                                 help='the file path where to download')

    args = parser.parse_args()

    # open SSH tunnel from GitLab Runner to the Ceph endpoint
    server = sshtunnel.SSHTunnelForwarder(
        (REMOTE_SERVER_IP, 20022),
        ssh_username=SSH_USER,
        ssh_pkey=args.ssh_key,
        ssh_private_key_password="@#$%^&*(",
        remote_bind_address=(PRIVATE_SERVER_IP, 80),
        local_bind_address=('0.0.0.0', 33380)
    )
    server.start()

    # perfrom S3 Ceph interface operation
    s3 = boto3.resource('s3',
                        endpoint_url=S3_CEPH_CREDENTIALS['s3_endpoint_url'],
                        aws_access_key_id=S3_CEPH_CREDENTIALS['s3_access_key_id'],
                        aws_secret_access_key=S3_CEPH_CREDENTIALS['s3_secret_access_key'])

    if args.action == "create_s3_bucket":
        s3.create_bucket(Bucket=args.bucket_name)
        response = s3.list_buckets()
        for bucket in response['Buckets']:
            print("{name}\t{created}".format(
                name=bucket['Name'],
                created=bucket['CreationDate'] ))

    elif args.action == "upload_s3_bucket":
        bucket = s3.Bucket(args.bucket_name)
        bucket.upload_file(Filename=args.file_name, Key=args.key_name)

    elif args.action == "query_s3_bucket":
        allFiles = s3.Bucket(args.bucket_name).objects.all()
        for file in allFiles:
            print(f"Ceph S3 file is uploaded as {file}")

    elif args.action == "download_s3_bucket":
        bucket = s3.Bucket(args.bucket_name)
        bucket.download_file(Filename=args.file_name, Key=args.key_name)

    # stop SSH tunnel
    server.stop()

if __name__ == '__main__':
    main()
