#! /bin/bash

# Fetch container image from upstream and push to local Harbor
# Bogdan Adrian Burciu 23/05/2022 vers 1

# -------------------------
# How to run: ./upstream_container_image_to_local_harbor.sh -s fluxcd/helm-controller:v0.21.0 -d <Harbor>/bogdan.burciu


# configure script to exit as soon as any line in the bash script fails and show that line
set -e

# using flags for passing input to script
while getopts s:d: flag
do
    case "${flag}" in
        s) source_image=${OPTARG};;
        d) destination_repo=${OPTARG};;
    esac
done

echo -e "\t\t >> docker image pull $source_image"
docker image pull $source_image
source_image_repo=`echo $source_image | awk -F":" '{print $1}'`
source_image_tag=`echo $source_image | awk -F":" '{print $2}'`
image_id=`docker image ls | grep $source_image_repo | grep $source_image_tag | grep -v $destination_repo | awk {'print $3'}`
echo -e "\t\t >> docker tag $image_id $destination_repo/$source_image_repo:$source_image_tag"
docker tag $image_id $destination_repo/$source_image_repo:$source_image_tag
destination_repo_fqdn=`echo $destination_repo | awk -F"/" '{print $1}'`
echo -e "\t\t >> docker login $destination_repo_fqdn"
docker login $destination_repo_fqdn
echo -e "\t\t >> docker push $destination_repo/$source_image_repo:$source_image_tag"
docker push $destination_repo/$source_image_repo:$source_image_tag
